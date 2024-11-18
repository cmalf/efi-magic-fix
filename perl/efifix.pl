#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor;
use File::Copy;
use File::Path qw(remove_tree);

# Color codes
my $RED = color('red');
my $BLUE = color('blue');
my $GREEN = color('green');
my $YELLOW = color('yellow');
my $UL = color('underline');
my $RESET = color('reset');

# Display coder sign
sub coder_mark {
    print <<HEREDOC;
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃$GREEN
┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮$BLUE
┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯$RESET
╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯

${UL}${GREEN}EFI Fixer Hackintosh ${RESET}${UL}v0.1${RESET}
HEREDOC
}

# Check if a partition is mounted
sub is_mounted {
    my ($partition) = @_;
    my $output = `mount`;
    return 0 unless $? == 0;
    
    foreach my $line (split /\n/, $output) {
        return 1 if $line =~ /$partition/ && $line =~ /type fat32/;
    }
    return 0;
}

# Get the EFI partition from the user
sub get_efi_partition {
    print "${YELLOW}\n(Executed diskutil list ~ [just copy EFI Partition])${RESET}\n";
    system('diskutil list');
    print "${GREEN}\nEnter EFI partition directory${RESET} (e.g., /dev/disk2s1): ";
    my $efi_partition = <STDIN>;
    chomp $efi_partition;

    unless (is_mounted($efi_partition)) {
        print "${RED}Partition is not mounted or invalid.\n${RESET}";
        print "${YELLOW}Do you want to mount now?${RED} Sudo Password Required!${RESET} (y/n) ";
        my $answer = <STDIN>;
        chomp $answer;
        system("sudo diskutil mount $efi_partition") if lc($answer) eq 'y';
    }

    return $efi_partition;
}

# Get the backup directory from the user
sub get_backup_dir {
    print "${YELLOW}\n(e.g., Below using pwd command ~ [just copy and paste enter])${RESET}\n";
    system('pwd');
    print "${GREEN}\nEnter Backup directory: ${RESET}";
    my $backup_dir = <STDIN>;
    chomp $backup_dir;
    return $backup_dir;
}

# Execute a system command and handle errors
sub execute_command {
    my ($command, $efi_partition) = @_;
    system($command);
    if ($? != 0) {
        my $error = $!;
        print "${RED}Error executing command: ${YELLOW}$error${RESET}\n";

        if ($error =~ /already unmounted/ || $error =~ /failed to unmount/) {
            print "${YELLOW}Trying to force unmount...${RESET}\n";
            system("sudo diskutil unmount force $efi_partition");
            if ($? != 0) {
                print "${RED}Forceful unmount failed: ${YELLOW}$!${RESET}\n";
                print "${RED}Please try rebooting your system and running the script again.${RESET}\n";
                exit(1);
            }
        } else {
            print "${RED}Unhandled error: ${YELLOW}$error${RESET}\n";
            print "${RED}Please check the system logs for more details.${RESET}\n";
            exit(1);
        }
    }
}

# Handle SIGINT
$SIG{INT} = sub {
    print "${RED}\nReceived SIGINT. Stopping Script with Peace...${RESET}\n";
    exit 0;
};

sub main {
    system('clear');
    coder_mark();

    my $backup_dir = get_backup_dir();
    my $efi_partition = get_efi_partition();
    my $vol_efi_dir = '/Volumes/EFI/';
    my $vol_efi_efi = '/Volumes/EFI/EFI';

    print "${YELLOW}\nChoose a method: \n${RESET}";
    print "1. ${GREEN}Format EFI partition and restore backup${RESET}\n";
    print "2. ${BLUE}Delete contents of EFI partition and restore backup${RESET}\n";
    print "3. ${RED}Exit${RESET}\n";

    print "\nEnter your choice: ";
    my $choice = <STDIN>;
    chomp $choice;

    if ($choice eq '1') {
        print "${GREEN}Starting format process and backup...${RESET}\n";
        execute_command("cd $vol_efi_dir && cp -r EFI $backup_dir", $efi_partition);
        execute_command("sudo diskutil unmount $efi_partition", $efi_partition);
        execute_command("sudo newfs_msdos -v EFI -F 32 $efi_partition", $efi_partition);
        execute_command("sudo diskutil mount $efi_partition", $efi_partition);
        execute_command("cd $backup_dir && cp -r EFI $vol_efi_dir", $efi_partition);
        print "${GREEN}Fixed EFI Partition Successfully..${RESET}\n";
    } elsif ($choice eq '2') {
        print "${RED}Starting deletion process and backup...${RESET}\n";
        execute_command("cd $vol_efi_dir && cp -r EFI $backup_dir", $efi_partition);
        remove_tree($vol_efi_efi);
        execute_command("cd $backup_dir && cp -r EFI $vol_efi_dir", $efi_partition);
        print "${GREEN}Fixed EFI Partition Successfully..${RESET}\n";
    } elsif ($choice eq '3') {
        system('clear');
        coder_mark();
        print "${GREEN}Thanks for using this script!${RESET}\n";
    } else {
        print "${RED}Invalid choice.${RESET}\n";
    }
}

main();

