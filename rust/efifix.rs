use std::process::{Command, exit};
use std::io::{self, Write};
use std::fs;
use std::path::Path;

// Color codes
const RED: &str = "\x1b[31m";
const BLUE: &str = "\x1b[34m";
const GREEN: &str = "\x1b[32m";
const YELLOW: &str = "\x1b[33m";
const UL: &str = "\x1b[4m";
const RESET: &str = "\x1b[0m";

// Display coder sign
fn coder_mark() {
    println!(r#"
    ╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
    ┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃{GREEN}
    ┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
    ┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮{BLUE}
    ┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
    ╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯{RESET}
    ╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
    ╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯

    {UL}{GREEN}EFI Fixer Hackintosh {RESET}{UL}v0.1{RESET}
    "#);
}

// Check if a partition is mounted
fn is_mounted(partition: &str) -> bool {
    let output = Command::new("mount")
        .output()
        .expect("Failed to execute mount command");

    if output.status.success() {
        String::from_utf8_lossy(&output.stdout)
            .lines()
            .any(|line| line.contains(partition) && line.contains("type fat32"))
    } else {
        println!("{}Error checking mount status{}", RED, RESET);
        false
    }
}

// Get the EFI partition from the user
fn get_efi_partition() -> String {
    println!("{}\n(Executed diskutil list ~ [just copy EFI Partition]){}", YELLOW, RESET);
    execute_command("diskutil list");
    print!("{}\nEnter EFI partition directory{} (e.g., /dev/disk2s1): ", GREEN, RESET);
    io::stdout().flush().unwrap();

    let mut efi_partition = String::new();
    io::stdin().read_line(&mut efi_partition).unwrap();
    let efi_partition = efi_partition.trim().to_string();

    if !is_mounted(&efi_partition) {
        println!("{}Partition is not mounted or invalid.\n{}", RED, RESET);
        print!("{}Do you want to mount now?{} Sudo Password Required!{} (y/n) ", YELLOW, RED, RESET);
        io::stdout().flush().unwrap();

        let mut answer = String::new();
        io::stdin().read_line(&mut answer).unwrap();
        if answer.trim().to_lowercase() == "y" {
            execute_command(&format!("sudo diskutil mount {}", efi_partition));
        }
    }

    efi_partition
}

// Get the backup directory from the user
fn get_backup_dir() -> String {
    println!("{}\n(e.g., Below using pwd command ~ [just copy and paste enter]){}", YELLOW, RESET);
    execute_command("pwd");
    print!("{}\nEnter Backup directory: {}", GREEN, RESET);
    io::stdout().flush().unwrap();

    let mut backup_dir = String::new();
    io::stdin().read_line(&mut backup_dir).unwrap();
    backup_dir.trim().to_string()
}

// Execute a system command and handle errors
fn execute_command(command: &str) {
    match Command::new("sh").arg("-c").arg(command).status() {
        Ok(status) => {
            if !status.success() {
                println!("{}Command failed: {}{}", RED, command, RESET);
            }
        }
        Err(e) => {
            println!("{}Error executing command: {}{}{}", RED, YELLOW, e, RESET);

            if e.to_string().contains("already unmounted") || e.to_string().contains("failed to unmount") {
                println!("{}Trying to force unmount...{}", YELLOW, RESET);
                if let Err(e) = Command::new("sudo").args(&["diskutil", "unmount", "force", "#{efi_partition}"]).status() {
                    println!("{}Forceful unmount failed: {}{}{}", RED, YELLOW, e, RESET);
                    println!("{}Please try rebooting your system and running the script again.{}", RED, RESET);
                    exit(1);
                }
            } else {
                println!("{}Unhandled error: {}{}{}", RED, YELLOW, e, RESET);
                println!("{}Please check the system logs for more details.{}", RED, RESET);
                exit(1);
            }
        }
    }
}

fn main() {
    Command::new("clear").status().unwrap();
    coder_mark();

    let backup_dir = get_backup_dir();
    let efi_partition = get_efi_partition();
    let vol_efi_dir = "/Volumes/EFI/";
    let vol_efi_efi = "/Volumes/EFI/EFI";

    println!("{}\nChoose a method: \n{}", YELLOW, RESET);
    println!("1. {}Format EFI partition and restore backup{}", GREEN, RESET);
    println!("2. {}Delete contents of EFI partition and restore backup{}", BLUE, RESET);
    println!("3. {}Exit{}", RED, RESET);

    print!("\nEnter your choice: ");
    io::stdout().flush().unwrap();

    let mut choice = String::new();
    io::stdin().read_line(&mut choice).unwrap();

    match choice.trim() {
        "1" => {
            println!("{}Starting format process and backup...{}", GREEN, RESET);
            execute_command(&format!("cd {} && cp -r EFI {}", vol_efi_dir, backup_dir));
            execute_command(&format!("sudo diskutil unmount {}", efi_partition));
            execute_command(&format!("sudo newfs_msdos -v EFI -F 32 {}", efi_partition));
            execute_command(&format!("sudo diskutil mount {}", efi_partition));
            execute_command(&format!("cd {} && cp -r EFI {}", backup_dir, vol_efi_dir));
            println!("{}Fixed EFI Partition Successfully..{}", GREEN, RESET);
        }
        "2" => {
            println!("{}Starting deletion process and backup...{}", RED, RESET);
            execute_command(&format!("cd {} && cp -r EFI {}", vol_efi_dir, backup_dir));
            fs::remove_dir_all(Path::new(vol_efi_efi)).unwrap();
            execute_command(&format!("cd {} && cp -r EFI {}", backup_dir, vol_efi_dir));
            println!("{}Fixed EFI Partition Successfully..{}", GREEN, RESET);
        }
        "3" => {
            Command::new("clear").status().unwrap();
            coder_mark();
            println!("{}Thanks for using this script!{}", GREEN, RESET);
        }
        _ => println!("{}Invalid choice.{}", RED, RESET),
    }
}

