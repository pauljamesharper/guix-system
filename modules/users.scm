(define-module (modules users)
  #:use-module (gnu system accounts)
  #:export (user-pharper podman-subids))

(define user-pharper
  (user-account
    (name "pharper")
    (comment "Paul Harper")
    (group "users")
    (home-directory "/home/pharper")
    (supplementary-groups '("wheel" "netdev"
                            "input"
                            "audio"
                            "video"
                            "i2c"
                            "kvm"
                            "libvirt"))))

(define podman-subids
  (map (lambda (user)
         (subid-range (name user)))
       '("pharper")))
