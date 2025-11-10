use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::process::Command;
use tempfile::NamedTempFile;
use log::{info, error, debug};

#[derive(Debug, Deserialize)]
struct Request {
    action: String,
    url: String,
}

#[derive(Debug, Serialize)]
struct Response {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    method: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    // Initialize logger (writes to ~/.copy-gif-extension/copy-gif-host.log)
    let log_dir = dirs::home_dir()
        .expect("Cannot find home directory")
        .join(".copy-gif-extension");

    std::fs::create_dir_all(&log_dir).ok();

    let log_file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_dir.join("copy-gif-host.log"))
        .expect("Cannot open log file");

    env_logger::Builder::new()
        .target(env_logger::Target::Pipe(Box::new(log_file)))
        .filter_level(log::LevelFilter::Info)
        .init();

    info!("Native messaging host started");
    info!("Platform: {}", std::env::consts::OS);

    // Read message from stdin
    match read_message() {
        Ok(request) => {
            info!("Received request: action={}, url={}", request.action, request.url);

            let response = match request.action.as_str() {
                "copyGif" => handle_copy_gif(&request.url),
                _ => Response {
                    success: false,
                    method: None,
                    error: Some(format!("Unknown action: {}", request.action)),
                },
            };

            if let Err(e) = send_message(&response) {
                error!("Failed to send response: {}", e);
            }
        }
        Err(e) => {
            error!("Failed to read message: {}", e);
            let response = Response {
                success: false,
                method: None,
                error: Some(format!("Failed to read message: {}", e)),
            };
            send_message(&response).ok();
        }
    }

    info!("Native messaging host exiting");
}

/// Read a message from stdin using Chrome's native messaging protocol
fn read_message() -> Result<Request, Box<dyn std::error::Error>> {
    let mut stdin = io::stdin();

    // Read 4-byte length prefix
    let mut length_bytes = [0u8; 4];
    stdin.read_exact(&mut length_bytes)?;
    let length = u32::from_ne_bytes(length_bytes);

    debug!("Message length: {}", length);

    // Read message
    let mut buffer = vec![0u8; length as usize];
    stdin.read_exact(&mut buffer)?;

    let message = String::from_utf8(buffer)?;
    debug!("Received message: {}", message);

    let request: Request = serde_json::from_str(&message)?;
    Ok(request)
}

/// Send a message to stdout using Chrome's native messaging protocol
fn send_message(response: &Response) -> Result<(), Box<dyn std::error::Error>> {
    let message = serde_json::to_string(response)?;
    let length = message.len() as u32;

    let mut stdout = io::stdout();
    stdout.write_all(&length.to_ne_bytes())?;
    stdout.write_all(message.as_bytes())?;
    stdout.flush()?;

    debug!("Sent message: {}", message);
    Ok(())
}

/// Handle copyGif action
fn handle_copy_gif(url: &str) -> Response {
    match download_and_copy_gif(url) {
        Ok(_) => {
            info!("Successfully copied GIF to clipboard");
            Response {
                success: true,
                method: Some("native".to_string()),
                error: None,
            }
        }
        Err(e) => {
            error!("Error copying GIF: {}", e);
            Response {
                success: false,
                method: None,
                error: Some(e.to_string()),
            }
        }
    }
}

/// Download GIF and copy to clipboard
fn download_and_copy_gif(url: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Convert WebP URLs to GIF if possible
    let gif_url = if url.ends_with(".webp") {
        let new_url = url.replace(".webp", ".gif");
        info!("Converted WebP URL to GIF: {}", new_url);
        new_url
    } else {
        url.to_string()
    };

    info!("Downloading GIF from: {}", gif_url);

    // Download GIF
    let response = reqwest::blocking::get(&gif_url)?;

    if !response.status().is_success() {
        return Err(format!("HTTP error: {}", response.status()).into());
    }

    let bytes = response.bytes()?;

    // Verify it's a GIF
    if !bytes.starts_with(b"GIF87a") && !bytes.starts_with(b"GIF89a") {
        return Err("Downloaded file is not a valid GIF".into());
    }

    info!("Downloaded {} bytes", bytes.len());

    // Save to temporary file
    let mut temp_file = NamedTempFile::new()?;
    temp_file.write_all(&bytes)?;
    temp_file.flush()?;

    let temp_path = temp_file.path();
    info!("Saved to temporary file: {:?}", temp_path);

    // Copy to clipboard based on OS
    #[cfg(target_os = "macos")]
    copy_to_clipboard_macos(temp_path)?;

    #[cfg(target_os = "windows")]
    copy_to_clipboard_windows(temp_path)?;

    #[cfg(target_os = "linux")]
    copy_to_clipboard_linux(temp_path)?;

    // Temp file is automatically deleted when it goes out of scope
    info!("Temporary file will be cleaned up");

    Ok(())
}

/// Copy GIF to clipboard on macOS using AppleScript
#[cfg(target_os = "macos")]
fn copy_to_clipboard_macos(path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    info!("Copying to clipboard on macOS");

    let path_str = path.to_str().ok_or("Invalid path")?;

    let applescript = format!(
        r#"set the clipboard to (read (POSIX file "{}") as «class GIFf»)"#,
        path_str
    );

    let output = Command::new("osascript")
        .arg("-e")
        .arg(&applescript)
        .output()?;

    if !output.status.success() {
        let error = String::from_utf8_lossy(&output.stderr);
        return Err(format!("osascript failed: {}", error).into());
    }

    info!("Successfully copied GIF to clipboard (macOS)");
    Ok(())
}

/// Copy GIF to clipboard on Windows using PowerShell
#[cfg(target_os = "windows")]
fn copy_to_clipboard_windows(path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    info!("Copying to clipboard on Windows");

    let path_str = path.to_str().ok_or("Invalid path")?;

    let powershell_script = format!(
        r#"
        Add-Type -AssemblyName System.Windows.Forms
        $file = Get-Item -LiteralPath "{}"
        $dataObject = New-Object System.Windows.Forms.DataObject
        $dataObject.SetFileDropList([System.Collections.Specialized.StringCollection]::new())
        $dataObject.GetFileDropList().Add($file.FullName)
        [System.Windows.Forms.Clipboard]::SetDataObject($dataObject, $true)
        "#,
        path_str
    );

    let output = Command::new("powershell")
        .arg("-Command")
        .arg(&powershell_script)
        .output()?;

    if !output.status.success() {
        let error = String::from_utf8_lossy(&output.stderr);
        return Err(format!("PowerShell failed: {}", error).into());
    }

    info!("Successfully copied GIF to clipboard (Windows)");
    Ok(())
}

/// Copy GIF to clipboard on Linux using xclip or wl-copy
#[cfg(target_os = "linux")]
fn copy_to_clipboard_linux(path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    info!("Copying to clipboard on Linux");

    let path_str = path.to_str().ok_or("Invalid path")?;

    // Try xclip first
    let xclip_result = Command::new("xclip")
        .args(["-selection", "clipboard", "-t", "image/gif", "-i", path_str])
        .output();

    match xclip_result {
        Ok(output) if output.status.success() => {
            info!("Successfully copied GIF to clipboard (Linux/xclip)");
            return Ok(());
        }
        _ => {
            // Try wl-copy (Wayland)
            let wlcopy_result = Command::new("wl-copy")
                .args(["--type", "image/gif"])
                .stdin(std::process::Stdio::piped())
                .spawn()
                .and_then(|mut child| {
                    if let Some(mut stdin) = child.stdin.take() {
                        std::fs::File::open(path_str)?
                            .bytes()
                            .try_for_each(|b| stdin.write_all(&[b?]))?;
                    }
                    child.wait()
                });

            match wlcopy_result {
                Ok(status) if status.success() => {
                    info!("Successfully copied GIF to clipboard (Linux/wl-copy)");
                    return Ok(());
                }
                _ => {
                    return Err("Neither xclip nor wl-copy is available".into());
                }
            }
        }
    }
}
