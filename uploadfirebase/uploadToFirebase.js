const admin = require("firebase-admin");
const fs = require("fs").promises; // Bruker promises for enklere asynkron flytkontroll
const path = require("path");

// Initialiser Firebase Admin SDK
const serviceAccount = require("./path-to-your-firebase-adminsdk-json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "gs://bachelor-7e242.appspot.com",
});

const bucket = admin.storage().bucket();

async function uploadFile(filePath, destination) {
  try {
    await bucket.upload(filePath, { destination });
    console.log(`${filePath} uploaded to ${destination}`);
  } catch (error) {
    console.error("Failed to upload file:", error);
  }
}

async function uploadDirectory(directoryPath, parentPath = "") {
  try {
    const files = await fs.readdir(directoryPath);
    for (const file of files) {
      const filePath = path.join(directoryPath, file);
      const stats = await fs.stat(filePath);
      if (stats.isDirectory()) {
        await uploadDirectory(filePath, path.join(parentPath, file)); // Rekursivt kall for undermapper
      } else {
        const destination = path.join(parentPath, file); // Lagrer filene i Firebase Storage med den samme mappestrukturen
        await uploadFile(filePath, destination);
      }
    }
  } catch (error) {
    console.error("Error processing directory:", error);
  }
}

// Startpunkt for opplasting
const scriptsDirPath = "./scriptsdeploy";
uploadDirectory(scriptsDirPath);
