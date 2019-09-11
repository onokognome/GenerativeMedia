
let  cell_lst = ["inC1a.wav"; "inC2a.wav"; "inC3a.wav"; "inC4a.wav"; "inC5a.wav";
   "inC6a.wav"; "inC7a.wav"; "inC8a.wav"; "inC9a.wav"; "inC10a.wav"]

let cell_location = "/home/dmakofka/inC/static/"

let sample_bytes_per_second = 4        (* bytes per sample - 2 lft 2 rt *)
                              * 44100  (* samples per second *)

let read_riff fi =
  let b = Bytes.create 4 in
  lwt _ = Lwt_io.read_into_exactly fi b 0 4 in
  lwt _ = Lwt_io.printlf "chunk:%s" (Bytes.to_string b) in
  lwt i = Lwt_io.LE.read_int32 fi in
  lwt _ = Lwt_io.printlf "size:%li" i in
  lwt _ = Lwt_io.read_into_exactly fi b 0 4  in
  Lwt_io.printlf "%s" (Bytes.to_string b)

let read_chunk_hdr fi bytes_to_skip =
  let b = Bytes.create 1024 in
  let _ = 
    if bytes_to_skip > 0 then
     let _ = Lwt_io.printlf "skipping %i bytes" bytes_to_skip in
     Lwt_io.read_into_exactly fi b 0 bytes_to_skip
    else Lwt.return () in
  let b = Bytes.create 4 in
  lwt _ = Lwt_io.read_into_exactly fi b 0 4 in
  let c = Bytes.to_string b in
  lwt _ = Lwt_io.printlf "chunk:%s" c in
  lwt i = Lwt_io.LE.read_int32 fi in
  lwt _ = Lwt_io.printlf "size:%i" (Int32.to_int i) in
  Lwt.return (c,(Int32.to_int i))


let read_header fi =
  let chunk_name = ref "" in
  let size = ref 0 in
  lwt _ = read_riff fi in
  lwt c,b = read_chunk_hdr fi 0 in (* fmt *)
  chunk_name := c; size := b;
  lwt c,b = read_chunk_hdr fi !size in (* junk *)
  chunk_name := c; size := b;
  lwt c,b = read_chunk_hdr fi !size in (* data *)
  chunk_name := c; size := b;
  Lwt.return !size


let write_wav_hdr fo secs =
  let sample_bytes = secs * sample_bytes_per_second in
  let riff_chunk_bytes = sample_bytes + 36 in
  lwt _ = Lwt_io.write_from_string_exactly fo "RIFF" 0 4 in
  lwt _ = Lwt_io.LE.write_int32 fo (Int32.of_int riff_chunk_bytes) in
  lwt _ = Lwt_io.write_from_string_exactly fo "WAVE" 0 4 in
  lwt _ = Lwt_io.write_from_string_exactly fo "fmt " 0 4 in 
  lwt _ = Lwt_io.LE.write_int32 fo (Int32.of_int 16) in
  lwt _ = Lwt_io.LE.write_int16 fo 1 in           (* pcm *)
  lwt _ = Lwt_io.LE.write_int16 fo 2 in           (* number of channels *)
  lwt _ = Lwt_io.LE.write_int32 fo (Int32.of_int 44100) in   (* sample rate *)
  lwt _ = Lwt_io.LE.write_int32 fo (Int32.of_int
                (44100 * 2 * 2) ) in                 (* byte rate *)
  lwt _ = Lwt_io.LE.write_int16 fo 4 in   (* block align num chan * bytes per sample*)
  lwt _ = Lwt_io.LE.write_int16 fo 16 in         (* bits per sample *)
  lwt _ = Lwt_io.write_from_string_exactly fo "data" 0 4 in
  lwt _ = Lwt_io.LE.write_int32 fo (Int32.of_int sample_bytes) in
  Lwt.return ()  


let new_player () =
 Lwt_mvar.create (0,0)

let start_player pval mixer_mbox samples = 
 let total_samples = ref samples in
 Lwt_list.iter_s (fun cell ->
 if !total_samples = 0 then Lwt.return () else (
 let cycles = ref (pval*3) in
 let times = ref 0 in
   lwt _ = Lwt_io.printlf "p:%i:%s" pval (cell_location ^ cell) in
   lwt fi = Lwt_io.open_file Lwt_io.Input (cell_location ^ cell) in
   lwt data_sz = read_header fi in
   lwt buf = Lwt.return (Bytes.create data_sz) in
   lwt _ = Lwt_io.read_into_exactly fi buf 0 data_sz in
   lwt in_chan = Lwt.return(Lwt_io.of_bytes Lwt_io.Input (Lwt_bytes.of_bytes buf)) in
   lwt _ =  times := data_sz/4; Lwt.return () in
   while_lwt (!times > 0) && (!total_samples > 0) do
     lwt l = Lwt_io.LE.read_int16 in_chan in
     lwt r = Lwt_io.LE.read_int16 in_chan in
(*     lwt _ = Lwt_io.printf "p%i:s:%i:t:%i:(%i,%i) " pval !total_samples !times l r in *)
     lwt _ = Lwt_mvar.put mixer_mbox (l,r) in
     decr times; decr total_samples;
     if !times = 0 then (
       lwt _ = decr cycles; Lwt.return () in
       if (!cycles > 0) then (
         lwt _ = times := data_sz/4; Lwt.return () in
         Lwt_io.set_position in_chan (Int64.of_int 0)
       ) else (
         Lwt.return ()
     ) ) else
       Lwt.return ()
   done)) cell_lst



let rec mixer mbox_lst fo times =
 lwt smpl_lst = Lwt_list.map_s ( fun mvar -> Lwt_mvar.take mvar) mbox_lst in
 lwt sl, sr = Lwt_list.fold_left_s (fun (il, ir) (l,r) -> Lwt.return ((il + l), (ir + r)) ) (0,0) smpl_lst in
 lwt _ = Lwt_io.write_int16 fo sl in
 lwt _ = Lwt_io.write_int16 fo sr in
 lwt _ = Lwt_io.flush fo in
(* lwt _ = Lwt_io.printlf "sample:%i" times in *) 
 if times > 1 then mixer mbox_lst fo (times - 1) else Lwt.return ()

let do_it players seconds out_filename =
 let rec build_mbox_lst players mbox_lst = (* build the mvar list *)
   if players = 0 then mbox_lst
   else build_mbox_lst (players -1) ((new_player()) :: mbox_lst) in

 (* open the output file and write the header *)
 lwt fo = Lwt_io.open_file Lwt_io.Output (cell_location ^ out_filename) in
 lwt _ = write_wav_hdr fo seconds in
   
 lwt mbox_lst = Lwt.return (build_mbox_lst players []) in

 (* flush the 'for nothing' 0 on mvar create*)
 lwt _ = Lwt_list.iter_p (fun mvar -> lwt _ = Lwt_mvar.take mvar in Lwt.return ()) mbox_lst in

  let pval = ref 0 in
  lwt _ = Lwt.join [ mixer mbox_lst fo (seconds*44100);
      (Lwt_list.iter_p (fun mbox -> incr pval; start_player !pval mbox (seconds*44100)) mbox_lst) 
    ] in  Lwt.return out_filename


(*
let _ = Lwt_main.run (
 do_it 4 30 "inCout.wav"

          )
*)