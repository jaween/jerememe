# Jerememe

![Jeremy cross-legged in meditation](https://jere.meme/m/u6GC6f8M.webp)

Unofficial Pure Pwnage meme maker.

Try it at: [https://jere.meme](https://jere.meme)

## Project Structure

`extractor/`: A script to extract and upload frames to an S3 bucket. Also parses the subtitles and adds them to a searchable database file.

`backend/`: A server to search for frames by subtitle and generates the meme images/videos.

`app/`: A Flutter web app client to provide a user interface.
