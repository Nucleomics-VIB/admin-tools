# How to Send Email via Gmail SMTP on Ubuntu Using msmtp

## 1. Install msmtp

Open a terminal and run:

```bash
sudo apt-get update
sudo apt-get install msmtp msmtp-mta
```

---

## 2. Create the msmtp Configuration File

Create a file named `.msmtprc` in your home directory:

```bash
nano ~/.msmtprc
```

Paste the following (replace with your Gmail address and App Password):

```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           youraddress@gmail.com
user           youraddress@gmail.com
password       YOUR_APP_PASSWORD

account default : gmail
```

- Replace `youraddress@gmail.com` with your Gmail address.
- Replace `YOUR_APP_PASSWORD` with your Gmail App Password (see below).

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

Set permissions:

```bash
chmod 600 ~/.msmtprc
```

---

## 3. Create a Gmail App Password

1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification if not already enabled.
3. Go to https://myaccount.google.com/apppasswords
4. Select "Other (Custom name)", enter "msmtp", and click "Generate".
5. Copy the 16-character password and use it in your `.msmtprc` as `YOUR_APP_PASSWORD`.

---

## 4. Test msmtp

Send a test email:

```bash
echo "Test mail from msmtp" | msmtp youraddress@gmail.com
```

Check your inbox and the log file `~/.msmtp.log` for errors.

---

## 5. Use msmtp in Your Script

Edit your script to use msmtp instead of sendmail. Replace the `mailit` function with:

```bash
mailit() {
    local fromopt="$1"
    local to="$2"
    local subject="$3"
    local messagefile="$4"

    if ! hash msmtp 2>/dev/null; then
        echo "# msmtp not installed or not in PATH" >&2
        return 1
    fi

    if [[ -z "$to" || -z "$subject" || -z "$messagefile" ]]; then
        echo "# to, subject, and message file are required!" >&2
        return 1
    fi

    local from
    if [[ -z "$fromopt" ]]; then
        from="$(whoami)@$(hostname)"
    else
        from="$fromopt"
    fi

    {
        echo "From: $from"
        echo "To: $to"
        echo "Subject: $subject"
        echo
        cat "$messagefile"
    } | msmtp -a gmail -f "$from" "$to"
}
```

---

Now, your Ubuntu server will send mail through Gmail using msmtp!
