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
