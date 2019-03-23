# Server
Due to the limitation of watchOS, it’s not possible to have WatchKit app to interact with Spotify’s accesspoint API directly for audio playback. In order to support audio streaming, Apollo requires a separate service to translate requests.

To avoid DMCA takedown of the project, I can't offer a reference implmentation. Go is a pretty cool language for this, and AWS Lamda/Google Cloud Function are sufficient for this kind of uses.

## Endpoints
### POST /token
This endpoint allows the app to request access token from Spotify’s auth service.

Request Body:
```json
{
  "code": "CODE"
}
```

Response:
```json
{
  "access_token": "ACCESS TOKEN",
  "refresh_token": "REFRESH TOKEN",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### POST /refresh
This endpoint allows the app to refresh access token using refresh token.

Request Body:
```json
{
  "refresh_token": "CODE"
}
```

Response:
```json
{
  "access_token": "ACCESS TOKEN",
  "refresh_token": "REFRESH TOKEN, Omit if unchange",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### POST /track
This endpoint allows the app to fetch track playback information for a single track. Please return the ogg file id for playback. Return 404 if the implementation can’t resolve a playable file. For key encryption, see DRM section.

Request Body:
```json
{
  "track_id": "Spotify's track ID",
  "token": "ACCESS TOKEN",
  "public_key": "Public key used to wrap the track decryption key"
}
```

Response:
```json
{
  "track_id": "Track ID",
  "file_id": "Spotify's file id for the track",
  "track_key": "Encrypted track key in Base64 encoded format"
}
```

### POST /tracks
This endpoint allows the app to fetch track playback information for a list of tracks. Please return the ogg file id for playback. For key encryption, see DRM section. You can omit track if the implementation if unable to resolve a particular track.

Request Body:
```json
{
  "track_ids": ["Spotify's track ID"],
  "token": "ACCESS TOKEN",
  "public_key": "Public key used to wrap the track decryption key"
}
```

Response:
```json
{
  "tracks": [
    {
      "track_id": "Track ID",
      "file_id": "Spotify's file id for the track",
      "track_key": "Encrypted track key in Base64 encoded format"
    }
  ]
}
```

### POST /storage-resolve
This endpoint returns a url to fetch the input file id. Return 404 if unable to find the resource.

Request Body:
```json
{
  "access_token": "ACCESS TOKEN",
  "file_id": "Spotify's File ID"
}
```

Response:
```json
{
  "url": "URL to the file"
}
```

## Poor Man’s DRM
To honor Spotify’s digital rights to the content, and avoid exposing a web service that returns the track AES key directly, Apollo implemented a key wrapping system utilizing Apple Watch’s Secure Enclave. Apollo generates an elliptic curve (P-256) key pair with Secure Enclave on Apple Watch, and expects all track key returned by the web service to encrypt the track key using the public key sent along with the request.

Apollo expects the track key to be encrypted in a way that’s compliant to  `kSecKeyAlgorithmECIESEncryptionCofactorVariableIVX963SHA256AESGCM`. For more information about server side encryption for Apple’s Security API, please refer to [Encrypting for Apple’s Secure Enclave | Darth Null](https://darthnull.org/security/2018/05/31/secure-enclave-ecies/). [Here](https://gist.github.com/KhaosT/73d56a3cd0496aefaa74c8e320602547) is an example in Go.