#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Minimal HIPAA-style audit logging and retention controls
void hipaa_init(const char* log_dir);
void hipaa_shutdown(void);
void hipaa_log_input(uint32_t device_id, int32_t dx, int32_t dy, int64_t ts_ms);
void hipaa_rotate(size_t max_bytes, int max_days);

// Best-effort encryption export (requires openssl CLI installed). Returns 1 on success.
int hipaa_encrypt_export(const char* dest_path, const char* passphrase);

#ifdef __cplusplus
}
#endif


