# libstorjiOSSwift4
libstorj code updates to support use with XCode 9+ and Swift 4+ derived from SwiftyStorj

100+ Error/Warnings in XCode Version 9.1 , Swift 4

1) 45 Implicit conversion loses integer precision: 'unsigned long' to 'int'

      Example:
      [original] int passphraselen = strlen(passphrase);
      [modify]   int passphraselen = (uint32_t) strlen(passphrase);

2) 25+ param[in] errors Parameter 'passphrase' not found in the function declaration

      Example: 
/**
 * @brief Will encrypt and write options to disk
 *
 * This will encrypt bridge and encryption options to disk using a key
 * derivation function on a passphrase.
 *
 * @param[in] filepath - The file path to save the options
 * @param[in] passphrase - Used to encrypt options to disk <-------
 * @param[in] bridge_user - The bridge username
 * @param[in] bridge_pass - The bridge password
 * @param[in] mnemonic - The file encryption mnemonic
 * @return A non-zero value on error, zero on success.
 */


int storj_encrypt_write_auth(const char *filepath,
                             const char *passhrase, <-------
                             const char *bridge_user,
                             const char *bridge_pass,
                             const char *mnemonic);

3) 37 Warning/Errors pending resolution:
       Example:
	src/uploader.c:1044:13: Variable 'response' is used uninitialized whenever 'if' condition is true
        src/rs.c:777:65: Implicit conversion loses integer precision: 'uint64_t' (aka 'unsigned long long') to 'int'

Concern:
4) 145 goto in 9 files, some of the goto's make it harder to setup unit level testing, etc. Evaluating removal of goto for use by Swift 4 as pod.

TODO:
5) 45 warnings/issues remain, primary root cause, conversion from gcc to llvm
and "data type conversion/precision", "uninitialize use of variables", "uninitialize use of variables, which is discouraged in Swift" Examples:

src/rs.c:777:65: Implicit conversion loses integer precision: 'uint64_t' (aka 'unsigned long long') to 'int'

src/uploader.c:1044:13: Variable 'response' is used uninitialized whenever 'if' condition is true

Pre-requisite, convert libstorj test cases before implementing "Concern" and "Todo" as QC precaution, especially for bitwise operators. Converting test cases will also deliver full functionality in Swift 4.

test_api();
test_api_badauth();
test_upload();
test_upload_cancel();
test_download();
test_download_cancel();
test_mnemonic_check();
test_mnemonic_generate();
test_storj_mnemonic_generate();
test_storj_mnemonic_generate_256();
test_generate_seed();
test_generate_seed_256();
test_generate_seed_256_trezor();
test_generate_bucket_key();
test_generate_file_key();
test_increment_ctr_aes_iv();
test_read_write_encrypted_file();
test_meta_encryption();
test_str2hex();
test_hex2str();
test_get_time_milliseconds();
test_determine_shard_size();
test_memory_mapping();

test_galois();
test_sub_matrix();
test_multiply();
test_inverse();
test_one_encoding();
test_one_decoding();
test_encoding();
test_reconstruct();
