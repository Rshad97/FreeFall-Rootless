# Rashad Repo signing

The shared Sileo/APT repository is published from `FreeFall-Rootless` to the `gh-pages` branch.

The publishing workflow supports authenticated APT metadata using an OpenPGP repository-signing key. The private key must never be committed to this public repository.

## GitHub Actions secrets

Configure these repository secrets under **Settings → Secrets and variables → Actions**:

- `REPO_GPG_PRIVATE_KEY` — the complete ASCII-armored private key, including the BEGIN/END lines.
- `REPO_GPG_PASSPHRASE` — the private-key passphrase. It may be empty only when the key itself has no passphrase.

Once configured, every successful repository publication creates:

- `Release`
- `Release.gpg`
- `InRelease`
- `rashad-repo-signing-key.asc`
- `rashad-repo-signing-key.gpg`

The workflow verifies both signatures before publishing.

## Recommended signing key

Use a dedicated repository-signing key rather than a personal identity key. RSA 3072 or RSA 4096 is suitable for broad APT compatibility. Keep the private key offline except for its encrypted GitHub Actions secret.

Example key generation on a trusted computer:

```sh
gpg --quick-generate-key "Rashad Repo <repo-signing@localhost>" rsa3072 sign 2y
gpg --list-secret-keys --keyid-format=long
gpg --armor --export-secret-keys <FINGERPRINT> > rashad-repo-private.asc
gpg --armor --export <FINGERPRINT> > rashad-repo-public.asc
```

Do not commit `rashad-repo-private.asc`.

## Trusting the repository on a rootless Dopamine device

After a signed publication exists, install the public key once:

```sh
su
mkdir -p /var/jb/etc/apt/trusted.gpg.d
curl -fsSL https://rshad97.github.io/FreeFall-Rootless/rashad-repo-signing-key.gpg \
  -o /var/jb/etc/apt/trusted.gpg.d/rashad-repo.gpg
chmod 0644 /var/jb/etc/apt/trusted.gpg.d/rashad-repo.gpg
rm -f /var/jb/var/lib/apt/lists/*rshad97* /var/jb/var/lib/apt/lists/*FreeFall*
apt clean
apt update
```

APT should then retrieve and authenticate `InRelease` (or `Release` + `Release.gpg`) without `--allow-unauthenticated`.

## Verification

On the published branch, confirm that `InRelease`, `Release.gpg`, and `rashad-repo-signing-key.gpg` exist. The workflow also runs `gpg --verify` before pushing the repository.
