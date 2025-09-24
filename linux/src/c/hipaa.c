#include "hipaa.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static char s_log_dir[512] = "";
static FILE* s_log = NULL;

static void ensure_dir(const char* path){ mkdir(path, 0700); }
static void open_log(){
    if (!s_log_dir[0]) return;
    char path[1024];
    snprintf(path, sizeof(path), "%s/audit.log", s_log_dir);
    s_log = fopen(path, "a");
}

void hipaa_init(const char* log_dir){
    if (!log_dir) return;
    snprintf(s_log_dir, sizeof(s_log_dir), "%s", log_dir);
    ensure_dir(s_log_dir);
    open_log();
}

void hipaa_shutdown(void){ if (s_log){ fclose(s_log); s_log=NULL; } }

void hipaa_log_input(uint32_t device_id, int32_t dx, int32_t dy, int64_t ts_ms){
    if (!s_log) return;
    // redact device id to pseudonymous form
    uint32_t pseudo = device_id ^ 0xA5A5A5A5u;
    fprintf(s_log, "%lld,MOUSE_INPUT,%u,%d,%d\n", (long long)ts_ms, pseudo, dx, dy);
    fflush(s_log);
}

static long file_size(const char* p){ struct stat st; if (stat(p,&st)==0) return st.st_size; return 0; }

void hipaa_rotate(size_t max_bytes, int max_days){
    if (!s_log_dir[0]) return;
    char path[1024]; snprintf(path,sizeof(path),"%s/audit.log",s_log_dir);
    long sz = file_size(path);
    if ((size_t)sz > max_bytes){
        // rotate with timestamp suffix
        char bak[1024];
        time_t t=time(NULL); struct tm tm; localtime_r(&t,&tm);
        snprintf(bak,sizeof(bak),"%s/audit-%04d%02d%02d-%02d%02d%02d.log",s_log_dir,tm.tm_year+1900,tm.tm_mon+1,tm.tm_mday,tm.tm_hour,tm.tm_min,tm.tm_sec);
        if (s_log){ fclose(s_log); s_log=NULL; }
        rename(path,bak);
        open_log();
    }
    // day-based retention left as an exercise or cron job
}

int hipaa_encrypt_export(const char* dest_path, const char* passphrase){
    if (!dest_path || !passphrase) return 0;
    char src[1024]; snprintf(src,sizeof(src),"%s/audit.log",s_log_dir);
    // Best-effort using openssl enc (AES-256-CBC)
    char cmd[2048];
    snprintf(cmd,sizeof(cmd),"openssl enc -aes-256-cbc -salt -in '%s' -out '%s' -pass pass:%s 2>/dev/null", src, dest_path, passphrase);
    int rc = system(cmd);
    return rc==0 ? 1 : 0;
}


