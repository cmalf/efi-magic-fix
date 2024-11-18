import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Scanner;

public class EFIFixer {
    // Color codes
    private static final String RED = "\u001B[31m";
    private static final String BLUE = "\u001B[34m";
    private static final String GREEN = "\u001B[32m";
    private static final String YELLOW = "\u001B[33m";
    private static final String UL = "\u001B[4m";
    private static final String RESET = "\u001B[0m";

    public static void main(String[] args) {
        clearScreen();
        coderMark();

        String backupDir = getBackupDir();
        String efiPartition = getEfiPartition();
        String volEfiDir = "/Volumes/EFI/";
        String volEfiEfi = "/Volumes/EFI/EFI";

        System.out.println(YELLOW + "\nChoose a method: \n" + RESET);
        System.out.println("1. " + GREEN + "Format EFI partition and restore backup" + RESET);
        System.out.println("2. " + BLUE + "Delete contents of EFI partition and restore backup" + RESET);
        System.out.println("3. " + RED + "Exit" + RESET);

        System.out.print("\nEnter your choice: ");
        Scanner scanner = new Scanner(System.in);
        String choice = scanner.nextLine();

        switch (choice) {
            case "1":
                System.out.println(GREEN + "Starting format process and backup..." + RESET);
                executeCommand("cd " + volEfiDir + " && cp -r EFI " + backupDir);
                executeCommand("sudo diskutil unmount " + efiPartition);
                executeCommand("sudo newfs_msdos -v EFI -F 32 " + efiPartition);
                executeCommand("sudo diskutil mount " + efiPartition);
                executeCommand("cd " + backupDir + " && cp -r EFI " + volEfiDir);
                System.out.println(GREEN + "Fixed EFI Partition Successfully.." + RESET);
                break;
            case "2":
                System.out.println(RED + "Starting deletion process and backup..." + RESET);
                executeCommand("cd " + volEfiDir + " && cp -r EFI " + backupDir);
                executeCommand("sudo rm -rf " + volEfiEfi);
                executeCommand("cd " + backupDir + " && cp -r EFI " + volEfiDir);
                System.out.println(GREEN + "Fixed EFI Partition Successfully.." + RESET);
                break;
            case "3":
                clearScreen();
                coderMark();
                System.out.println(GREEN + "Thanks for using this script!" + RESET);
                break;
            default:
                System.out.println(RED + "Invalid choice." + RESET);
        }

        scanner.close();
    }

    private static void coderMark() {
        System.out.println(
            "╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮\n" +
            "┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃" + GREEN + "\n" +
            "┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮\n" +
            "┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮" + BLUE + "\n" +
            "┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃\n" +
            "╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯" + RESET + "\n" +
            "╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃\n" +
            "╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯\n\n" +
            UL + GREEN + "EFI Fixer Hackintosh " + RESET + UL + "v0.1" + RESET
        );
    }

    private static boolean isMounted(String partition) {
        try {
            Process process = Runtime.getRuntime().exec("mount");
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains(partition) && line.contains("type fat32")) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            System.out.println(RED + "Error checking mount status: " + e.getMessage() + RESET);
            return false;
        }
    }

    private static String getEfiPartition() {
        System.out.println(YELLOW + "\n(Executed diskutil list ~ [just copy EFI Partition])" + RESET);
        executeCommand("diskutil list");
        System.out.print(GREEN + "\nEnter EFI partition directory" + RESET + " (e.g., /dev/disk2s1): ");
        Scanner scanner = new Scanner(System.in);
        String efiPartition = scanner.nextLine().trim();

        if (!isMounted(efiPartition)) {
            System.out.println(RED + "Partition is not mounted or invalid.\n" + RESET);
            System.out.print(YELLOW + "Do you want to mount now?" + RED + " Sudo Password Required!" + RESET + " (y/n) ");
            String answer = scanner.nextLine().toLowerCase();
            if (answer.equals("y")) {
                executeCommand("sudo diskutil mount " + efiPartition);
            }
        }

        return efiPartition;
    }

    private static String getBackupDir() {
        System.out.println(YELLOW + "\n(e.g., Below using pwd command ~ [just copy and paste enter])" + RESET);
        executeCommand("pwd");
        System.out.print(GREEN + "\nEnter Backup directory: " + RESET);
        Scanner scanner = new Scanner(System.in);
        return scanner.nextLine().trim();
    }

    private static void executeCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(command);
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
            process.waitFor();
        } catch (Exception e) {
            System.out.println(RED + "Error executing command: " + YELLOW + e.getMessage() + RESET);

            if (e.getMessage().contains("already unmounted") || e.getMessage().contains("failed to unmount")) {
                System.out.println(YELLOW + "Trying to force unmount..." + RESET);
                try {
                    Runtime.getRuntime().exec("sudo diskutil unmount force " + getEfiPartition());
                } catch (Exception ex) {
                    System.out.println(RED + "Forceful unmount failed: " + YELLOW + ex.getMessage() + RESET);
                    System.out.println(RED + "Please try rebooting your system and running the script again." + RESET);
                    System.exit(1);
                }
            } else {
                System.out.println(RED + "Unhandled error: " + YELLOW + e.getMessage() + RESET);
                System.out.println(RED + "Please check the system logs for more details." + RESET);
                System.exit(1);
            }
        }
    }

    private static void clearScreen() {
        System.out.print("\033[H\033[2J");
        System.out.flush();
    }
}

