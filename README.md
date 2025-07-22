# DOMjudge Management Scripts

These are a bunch of helper scripts to manage the DOMjudge setup quickly through Docker. Most of them just make life easier when dealing with services, backups, or common restarts.

## Step-by-Step Instructions

1. **Install Docker**  
   - Make sure Docker is installed before continuing.

2. **Configure the Environment File**  
   - Copy the provided template to create your `.env` file:  
     ```bash
     cp .env.template .env
     ```  
   - Edit the `.env` file with your preferred settings (ports, passwords, versions, etc.):  
     ```bash
     nano .env
     ```

3. **Run the System Startup Script**  
   - Make the script executable:  
     ```bash
     chmod +x start_system.sh
     ```  
   - Run the script with sudo privileges:  
     ```bash
     sudo ./start_system.sh
     ```

4. **Wait for the Server to Boot Up**  
   - Wait until the judgehost connects to the domserver.

5. **Troubleshoot cgroup Memory Error**  
   - If you encounter the error during boot-up:  
     ```
     Error: cgroup support missing memory features in running kernel. Unable to continue.
     ```  
     This indicates that the Linux kernel lacks required cgroup memory features, which are necessary for the judgehost or system to function.

   - **Steps to Resolve**:  
     1. Stop the system to prevent further issues:  
        ```bash
        sudo ./stop_system.sh
        ```  
        Ensure the `stop_system.sh` script is executable:  
        ```bash
        chmod +x stop_system.sh
        ```  
     2. Enable cgroup memory features:  
        - Edit the GRUB configuration:  
          ```bash
          sudo nano /etc/default/grub
          ```  
        - Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` and append:  
          ```
          cgroup_enable=memory cgroup_memory=1
          ```  
          Example:  
          ```
          GRUB_CMDLINE_LINUX_DEFAULT="quiet splash cgroup_enable=memory cgroup_memory=1"
          ```  
        - Save the file and update GRUB:  
          ```bash
          sudo update-grub
          ```  
        - Reboot your system:  
          ```bash
          sudo reboot
          ```  
     3. Start the system again:  
        ```bash
        sudo ./start_system.sh
        ```

6. **Verify System Operation**  
   - Once the server starts without errors, open [http://localhost:12345/](http://localhost:12345/) in your browser.  
   - You should see the DOMjudge interface and be able to use the system normally.

## Accessing the Database via phpMyAdmin

Once the system is running you can manage the DOMjudge database visually using **phpMyAdmin**, which is exposed on port `8080` by default (see `.env.template` file).

To access it:

1. Open your browser and go to [http://localhost:8080](http://localhost:8080)
2. Use the following credentials:
   - **Username:** `root` or the value of `MYSQL_USER` in `.env`
   - **Password:** the value of `MYSQL_ROOT_PASSWORD` or `MYSQL_PASSWORD` in `.env`
3. Select the `domjudge` database from the left panel.
4. You can now:
   - Browse tables
   - Run SQL queries
   - Export/import data
   - Inspect or debug DOMjudge's internal state

## Scripts Overview

### `start_system.sh`
Starts all the containers: DB, DOMserver, judgehost, and phpMyAdmin. Use this to boot everything up.

---

### `stop_system.sh`
Stops all running containers cleanly. Use it when shutting everything down or before making system-level changes.

---

### `get_passwords.sh`
Prints all important passwords from domserver container. Useful when you forget credentials and don't want to open the container logs and look for them manually.

Note this isn't insecure because the container itself exposes the passwords in the logs, it’s just more convenient this way.

---

### `make_db_backup.sh`  
Creates a `.sql` backup of the DOMjudge database using the root user. Saves it in the `./backups` folder with a timestamp. You can run this manually or with crontab.

**Example crontab entry to run this script every day at 2:30 AM:**

```bash
30 2 * * * /path/to/make_db_backup.sh >> /path/to/backup.log 2>&1
```

This will:
- Run the script every day at 02:30.
- Append logs to `backup.log`.
- Redirect errors to the same file.

To edit your crontab, run:
```bash
crontab -e
```

Make sure the script is executable:
```bash
chmod +x /path/to/make_db_backup.sh
```

And that the path in the crontab is absolute (no `./relative/path`).

---

### `restore_db_backup.sh`
Shows you a list of all the available backups, lets you choose one, and restores it to the database. It'll overwrite current data, so be sure before confirming.

---

### `restart_domserver.sh`
Restarts the DOMserver container (the main web interface). Use it if the site is acting up or you made changes that need a reload.

---

### `restart_judgehost.sh`
Restarts the judgehost container. This is the part that compiles and tests code submissions. Restart it if something crashes or freezes.

---

### `restart_mariadb.sh`
Restarts the MariaDB container (the actual database). Use this if the DB stops responding or after restoring a backup.

---

### `restart_phpmyadmin.sh`
Restarts the phpMyAdmin container. Handy when you can’t connect or it’s glitchy.

---

## Notes and Trouble Shouting 
- All scripts expect a working `.env` file in the same directory, you can use `.env.template` to create the `.env` file, it has the same structure.
- Make sure Docker is installed and running.
- Scripts are written for a typical local dev/test setup — adapt them if needed for production.

### Judgehost fails with cgroup memory error

If your judgehost throws this error when starting:

```
Error: cgroup support missing memory features in running kernel. Unable to continue.
To fix this, please make the following changes:
    1. In /etc/default/grub, add 'cgroup_enable=memory swapaccount=1' to GRUB_CMDLINE_LINUX_DEFAULT.
       On modern distros (e.g. Debian bullseye and Ubuntu Jammy Jellyfish) which have cgroup v2 enabled by default,
       you need to add 'systemd.unified_cgroup_hierarchy=0' as well.
    2. Run update-grub
    3. Reboot
```

This means your system is missing required **cgroup memory support**, which is necessary for the judgehost to work.

To fix it:

1. Open the GRUB config:
   ```bash
   sudo nano /etc/default/grub
   ```

2. Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` and append the following to the existing options:
   ```
   cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0
   ```

   Example:
   ```bash
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0"
   ```

3. Save and exit, then update GRUB:
   ```bash
   sudo update-grub
   ```

4. Reboot the system:
   ```bash
   sudo reboot
   ```
