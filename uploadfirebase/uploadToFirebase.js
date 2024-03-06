const admin = require("firebase-admin");
const fs = require("fs").promises; // Bruker promises for enklere asynkron flytkontroll
const path = require("path");

// Initialiser Firebase Admin SDK
const serviceAccount = require("../serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "gs://bachelor-7e242.appspot.com",
});

const bucket = admin.storage().bucket();

// Funksjon for å laste opp filer
async function uploadFile(filePath, destination) {
  try {
    await bucket.upload(filePath, { destination });
    console.log(`${filePath} uploaded to ${destination}`);
    return destination; // Returner destinasjonen for suksessfull opplasting
  } catch (error) {
    console.error("Failed to upload file:", error);
    return null; // Returner null hvis opplasting feilet
  }
}

// Funksjon for å rekursivt laste opp en mappe
async function uploadDirectory(directoryPath, parentPath = "") {
  let uploadedFiles = []; // Holder styr på opplastede filstier

  try {
    const files = await fs.readdir(directoryPath);
    for (const file of files) {
      const filePath = path.join(directoryPath, file);
      const stats = await fs.stat(filePath);
      if (stats.isDirectory()) {
        // Rekursivt kall for undermapper
        const uploadedSubFiles = await uploadDirectory(
          filePath,
          path.join(parentPath, file)
        );
        uploadedFiles = uploadedFiles.concat(uploadedSubFiles); // Legg til filer fra undermapper
      } else {
        // Opplast og lagre destinasjonen for filen
        const destination = path.join(parentPath, file);
        const uploadedFilePath = await uploadFile(filePath, destination);
        if (uploadedFilePath) {
          uploadedFiles.push(uploadedFilePath); // Lagre kun suksessfulle opplastinger
        }
      }
    }
  } catch (error) {
    console.error("Error processing directory:", error);
  }

  return uploadedFiles; // Returner listen over opplastede filer
}

// Funksjon for å liste alle filer i en Firebase Storage Bucket
async function listAllFiles(bucket) {
  const [files] = await bucket.getFiles();
  return files.map((file) => file.name);
}

// Funksjon for å slette filer som ikke lenger finnes i GitHub-repositoriet
async function deleteOrphanedFiles(bucket, uploadedFiles) {
  const existingFiles = await listAllFiles(bucket);
  const filesToDelete = existingFiles.filter(
    (file) => !uploadedFiles.includes(file)
  );

  for (const file of filesToDelete) {
    await bucket.file(file).delete();
    console.log(`Deleted orphaned file: ${file}`);
  }
}

// Hovedfunksjon for å koordinere opplasting og sletting
async function main() {
  const uploadedFiles = await uploadDirectory("./scriptsdeploy");
  await deleteOrphanedFiles(bucket, uploadedFiles);
}

main();
