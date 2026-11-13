use hbb_common::config;

pub const DISPLAY_NAME: &str = "旋转木马远程桌面";
pub const INTERNAL_NAME: &str = "CarouselRemote";

pub fn display_name() -> String {
    if cfg!(windows) {
        DISPLAY_NAME.to_owned()
    } else {
        crate::get_app_name()
    }
}

#[cfg(windows)]
pub fn apply() {
    *config::APP_NAME.write().unwrap() = INTERNAL_NAME.to_owned();
    let data: serde_json::Value =
        match serde_json::from_str(include_str!("../res/carousel/client.json")) {
            Ok(data) => data,
            Err(err) => {
                hbb_common::log::error!("Invalid Carousel server configuration: {}", err);
                return;
            }
        };
    let mut settings = config::OVERWRITE_SETTINGS.write().unwrap();
    for (option, field) in [
        ("custom-rendezvous-server", "id_server"),
        ("relay-server", "relay_server"),
        ("key", "public_key"),
    ] {
        if let Some(value) = data[field].as_str() {
            settings.insert(option.to_owned(), value.to_owned());
        }
    }
}
