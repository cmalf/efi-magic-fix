require 'open3'
require 'fileutils'

# Color codes
RED = "\e[31m"
BLUE = "\e[34m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
UL = "\e[4m"
RESET = "\e[0m"

# Display coder sign
def coder_mark
  puts <<~HEREDOC
    ╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
    ┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃#{GREEN}
    ┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
    ┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮#{BLUE}
    ┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
    ╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯#{RESET}
    ╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
    ╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯

    #{UL}#{GREEN}EFI Fixer Hackintosh #{RESET}#{UL}v0.1#{RESET}
  HEREDOC
end

# Check if a partition is mounted
def is_mounted?(partition)
  output, status = Open3.capture2('mount')
  return false unless status.success?

  output.split("\n").any? { |line| line.include?(partition) && line.include?("type fat32") }
rescue StandardError => e
  puts "#{RED}Error checking mount status: #{e.message}#{RESET}"
  false
end

# Get the EFI partition from the user
def get_efi_partition
  puts "#{YELLOW}\n(Executed diskutil list ~ [just copy EFI Partition])#{RESET}"
  execute_command('diskutil list')
  print "#{GREEN}\nEnter EFI partition directory#{RESET} (e.g., /dev/disk2s1): "
  efi_partition = gets.chomp.strip

  unless is_mounted?(efi_partition)
    puts "#{RED}Partition is not mounted or invalid.\n#{RESET}"
    print "#{YELLOW}Do you want to mount now?#{RED} Sudo Password Required!#{RESET} (y/n) "
    answer = gets.chomp.downcase
    execute_command("sudo diskutil mount #{efi_partition}") if answer == 'y'
  end

  efi_partition
end

# Get the backup directory from the user
def get_backup_dir
  puts "#{YELLOW}\n(e.g., Below using pwd command ~ [just copy and paste enter])#{RESET}"
  execute_command('pwd')
  print "#{GREEN}\nEnter Backup directory: #{RESET}"
  backup_dir = gets.chomp.strip
  backup_dir
end

# Execute a system command and handle errors
def execute_command(command)
  system(command)
rescue StandardError => e
  puts "#{RED}Error executing command: #{YELLOW}#{e.message}#{RESET}"

  if e.message.include?('already unmounted') || e.message.include?('failed to unmount')
    puts "#{YELLOW}Trying to force unmount...#{RESET}"
    begin
      system('sudo diskutil unmount force #{efi_partition}')
    rescue StandardError => e
      puts "#{RED}Forceful unmount failed: #{YELLOW}#{e.message}#{RESET}"
      puts "#{RED}Please try rebooting your system and running the script again.#{RESET}"
      exit(1)
    end
  else
    puts "#{RED}Unhandled error: #{YELLOW}#{e.message}#{RESET}"
    puts "#{RED}Please check the system logs for more details.#{RESET}"
    exit(1)
  end
end

# Handle SIGINT
Signal.trap('INT') do
  puts "#{RED}\nReceived SIGINT. Stopping Script with Peace...#{RESET}"
  exit 0
end

def main
  system('clear')
  coder_mark

  backup_dir = get_backup_dir
  efi_partition = get_efi_partition
  vol_efi_dir = '/Volumes/EFI/'
  vol_efi_efi = '/Volumes/EFI/EFI'

  puts "#{YELLOW}\nChoose a method: \n#{RESET}"
  puts "1. #{GREEN}Format EFI partition and restore backup#{RESET}"
  puts "2. #{BLUE}Delete contents of EFI partition and restore backup#{RESET}"
  puts "3. #{RED}Exit#{RESET}"

  print "\nEnter your choice: "
  choice = gets.chomp

  case choice
  when '1'
    puts "#{GREEN}Starting format process and backup...#{RESET}"
    execute_command("cd #{vol_efi_dir} && cp -r EFI #{backup_dir}")
    execute_command("sudo diskutil unmount #{efi_partition}")
    execute_command("sudo newfs_msdos -v EFI -F 32 #{efi_partition}")
    execute_command("sudo diskutil mount #{efi_partition}")
    execute_command("cd #{backup_dir} && cp -r EFI #{vol_efi_dir}")
    puts "#{GREEN}Fixed EFI Partition Successfully..#{RESET}"
  when '2'
    puts "#{RED}Starting deletion process and backup...#{RESET}"
    execute_command("cd #{vol_efi_dir} && cp -r EFI #{backup_dir}")
    execute_command("sudo rm -rf #{vol_efi_efi}")
    execute_command("cd #{backup_dir} && cp -r EFI #{vol_efi_dir}")
    puts "#{GREEN}Fixed EFI Partition Successfully..#{RESET}"
  when '3'
    system('clear')
    coder_mark
    puts "#{GREEN}Thanks for using this script!#{RESET}"
  else
    puts "#{RED}Invalid choice.#{RESET}"
  end
end

main