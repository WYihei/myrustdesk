fn main() {
    println!("cargo:rerun-if-changed=../../res/icon.ico");
    println!("cargo:rerun-if-changed=../../res/manifest.xml");
    println!("cargo:rerun-if-changed=Cargo.toml");
    #[cfg(windows)]
    {
        use std::io::Write;
        let mut res = winres::WindowsResource::new();
        res.set_icon_with_id("../../res/icon.ico", "101")
            .set_language(winapi::um::winnt::MAKELANGID(
                winapi::um::winnt::LANG_ENGLISH,
                winapi::um::winnt::SUBLANG_ENGLISH_US,
            ))
            .set_manifest_file("../../res/manifest.xml");
        match res.compile() {
            Err(e) => {
                write!(std::io::stderr(), "{}", e).unwrap();
                std::process::exit(1);
            }
            Ok(_) => {}
        }
    }
}
