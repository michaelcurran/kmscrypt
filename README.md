# KMSCrypt
# What does this do?
This is a ruby script that utilizes the AWS Key Management Service (KMS) to help securely encrypt and decrypt files.  It also provides a method to upload these encrypted files to an AWS S3 bucket, from where the files can be updated, downloaded, or deleted.
# How is it secure?
KMS provides a way of encrypting and decrypting files without having to store the plaintext key used during the encryption process locally.  Using KMS, you create a customer master key (CMK), which provides a CMK ID.  The CMK ID is used to provide a unique encrypted key and plaintext key version of the CMK data key.  The plaintext key is used to encrypt/decrypt the data, and is then discarded.  The encrypted key is saved, as it is used to retrieve the plaintext key.

For example, when encrypting a file with `./kmscrypt encrypt file_name`, the kmscrypt script uses the CMK ID to retrieve the plaintext and encrypted key.  It then uses the plaintext key in order to AES256 encrypt the file, discarding the plaintext key when done.  The encrypted data is then stored, along with the encrypted data key.  When this file needs to be decrypted with `kmscrypt decrypt file`, the script uses the encrypted data key, which is stored along side the encrypted data, to retrieve the plaintext key from KMS, and decrypt the data using the plaintext key, which is then discarded again.

Additionally, in order to access KMS, you need an IAM user or IAM role with access, which should help in providing another level of security.
## Setup
1. Setup KMS
   - Go to the IAM tab of the AWS console
   - Click on "Encryption Keys" in the left nav menu
   - Click "Create Key" at the top. 
     - For "Alias (required)", put any logical name.
     - For "Key Administrators", pick the user(s) that has access to manage the key itself
     - For "Key Usage Permissions", pick the IAM user(s) or role(s) that have access to use this script.
     - Record the Key ID created
2. Setup kmscrypt
    - Have ruby and bundler installed
    - Clone the repo
    - Run the `bundle install` command within the locally cloned repo
    - Do one of the following:
      - Setup an environment variable for the Key ID created above, with something like: `export CMK_KEY_ID=<Key ID here>`
      - Update the keyId variable in the encrypt method, line 12, within lib/kms.rb
    - Provide an S3 bucket name for the bucket variable on line 9 of the kmscrypt script
    - Have an IAM role setup that allows access from the instance the script is running on, or configure the IAM keys in environment variables or in a file (directions in the links below):
      - http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment
      - http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files
