[%%shared
    open Eliom_lib
    open Eliom_content
    open Html5.F
]

module InC_app =
  Eliom_registration.App (
    struct
      let application_name = "inC"
    end)

let main_service =
  Eliom_service.App.service ~path:[] ~get_params:Eliom_parameter.unit ()



let audio_mk_file (nAccords,len) = 
  Wavefile.do_it nAccords len "inc.wav"


open Eliom_parameter  (* for ** *)

let send_audio_mk_file_srv =
  Eliom_registration.File.register_service
    ~path:["audio"]
    ~get_params:Eliom_parameter.(suffix (int "nAccords" ** int "len"))
   (fun (nAccords,len) () ->  audio_mk_file (nAccords,len))



let send_audio_file =
  Eliom_registration.File.register_service
    ~path:["audiof"]
    ~get_params:Eliom_parameter.(suffix (all_suffix "filename"))
    (fun s () ->
      Lwt.return ("static/"^(Ocsigen_lib.Url.string_of_url_path ~encode:false s)))


(*
let send_audio_ocaml  =
    Eliom_registration.Ocaml.register_post_coservice'
    ~post_params:Eliom_parameter.unit
    (fun (a,l) -> Lwt.return "static/music.mp3")
*)

let () =
  InC_app.register
    ~service:main_service
    (fun () () -> let fname = Wavefile.do_it 4 15 "inc.wav" in
      Lwt.bind fname (fun fname ->
      Lwt_io.printlf "%s" fname;
      Lwt.return
        (
        Eliom_tools.F.html
           ~title:"inC"
           ~css:[["css";"inC.css"]]
           Html5.F.(body[
             h2 [pcdata "In C"]; 
             (*Eliom_content.Html5.Id.create_global_elt *)(audio
               ~src:( make_uri (Eliom_service.static_dir ())  
                          ["static"; fname ] )
               ~a:[a_autoplay (`Autoplay);a_controls (`Controls)]
               [pcdata "Your browser does not support audio element" ])
           ])) ) )
