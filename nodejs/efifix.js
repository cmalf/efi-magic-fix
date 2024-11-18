const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Color codes
const RED = "\x1b[31m";
const BLUE = "\x1b[34m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const UL = "\x1b[4m";
const RESET = "\x1b[0m";

// Display coder sign
function coderMark() {
  console.log(`
    ╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
    ┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃${GREEN}
    ┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
    ┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮${BLUE}
    ┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
    ╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯${RESET}
    ╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
    ╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯

    ${UL}${GREEN}EFI Fixer Hackintosh ${RESET}${UL}v0.1${RESET}
  `);
}

// Check if a partition is mounted
function isMounted(partition) {
  try {
    const output = execSync('mount').toString();
    return output.split('\n').some(line => line.includes(partition) && line.includes("type fat32"));
  } catch (e) {
    console.log(`${RED}Error checking mount status: ${e.message}${RESET}`);
    return false;
  }
}

// Get the EFI partition from the user
function getEfiPartition() {
  console.log(`${YELLOW}\n(Executed diskutil list ~ [just copy EFI Partition])${RESET}`);
  executeCommand('diskutil list');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(`${GREEN}\nEnter EFI partition directory${RESET} (e.g., /dev/disk2s1): `, (efiPartition) => {
      efiPartition = efiPartition.trim();

      if (!isMounted(efiPartition)) {
        console.log(`${RED}Partition is not mounted or invalid.\n${RESET}`);
        rl.question(`${YELLOW}Do you want to mount now?${RED} Sudo Password Required!${RESET} (y/n) `, (answer) => {
          if (answer.toLowerCase() === 'y') {
            executeCommand(`sudo diskutil mount ${efiPartition}`);
          }
          rl.close();
          resolve(efiPartition);
        });
      } else {
        rl.close();
        resolve(efiPartition);
      }
    });
  });
}

// Get the backup directory from the user
function getBackupDir() {
  console.log(`${YELLOW}\n(e.g., Below using pwd command ~ [just copy and paste enter])${RESET}`);
  executeCommand('pwd');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(`${GREEN}\nEnter Backup directory: ${RESET}`, (backupDir) => {
      rl.close();
      resolve(backupDir.trim());
    });
  });
}

// Execute a system command and handle errors
function executeCommand(command) {
  try {
    execSync(command, { stdio: 'inherit' });
  } catch (e) {
    console.log(`${RED}Error executing command: ${YELLOW}${e.message}${RESET}`);

    if (e.message.includes('already unmounted') || e.message.includes('failed to unmount')) {
      console.log(`${YELLOW}Trying to force unmount...${RESET}`);
      try {
        execSync(`sudo diskutil unmount force ${efiPartition}`);
      } catch (e) {
        console.log(`${RED}Forceful unmount failed: ${YELLOW}${e.message}${RESET}`);
        console.log(`${RED}Please try rebooting your system and running the script again.${RESET}`);
        process.exit(1);
      }
    } else {
      console.log(`${RED}Unhandled error: ${YELLOW}${e.message}${RESET}`);
      console.log(`${RED}Please check the system logs for more details.${RESET}`);
      process.exit(1);
    }
  }
}

// Handle SIGINT
process.on('SIGINT', () => {
  console.log(`${RED}\nReceived SIGINT. Stopping Script with Peace...${RESET}`);
  process.exit(0);
});

async function main() {
  console.clear();
  coderMark();

  const backupDir = await getBackupDir();
  const efiPartition = await getEfiPartition();
  const volEfiDir = '/Volumes/EFI/';
  const volEfiEfi = '/Volumes/EFI/EFI';

  console.log(`${YELLOW}\nChoose a method: \n${RESET}`);
  console.log(`1. ${GREEN}Format EFI partition and restore backup${RESET}`);
  console.log(`2. ${BLUE}Delete contents of EFI partition and restore backup${RESET}`);
  console.log(`3. ${RED}Exit${RESET}`);

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('\nEnter your choice: ', (choice) => {
    rl.close();

    switch (choice) {
      case '1':
        console.log(`${GREEN}Starting format process and backup...${RESET}`);
        executeCommand(`cd ${volEfiDir} && cp -r EFI ${backupDir}`);
        executeCommand(`sudo diskutil unmount ${efiPartition}`);
        executeCommand(`sudo newfs_msdos -v EFI -F 32 ${efiPartition}`);
        executeCommand(`sudo diskutil mount ${efiPartition}`);
        executeCommand(`cd ${backupDir} && cp -r EFI ${volEfiDir}`);
        console.log(`${GREEN}Fixed EFI Partition Successfully..${RESET}`);
        break;
      case '2':
        console.log(`${RED}Starting deletion process and backup...${RESET}`);
        executeCommand(`cd ${volEfiDir} && cp -r EFI ${backupDir}`);
        executeCommand(`sudo rm -rf ${volEfiEfi}`);
        executeCommand(`cd ${backupDir} && cp -r EFI ${volEfiDir}`);
        console.log(`${GREEN}Fixed EFI Partition Successfully..${RESET}`);
        break;
      case '3':
        console.clear();
        coderMark();
        console.log(`${GREEN}Thanks for using this script!${RESET}`);
        break;
      default:
        console.log(`${RED}Invalid choice.${RESET}`);
    }
  });
}

main();

