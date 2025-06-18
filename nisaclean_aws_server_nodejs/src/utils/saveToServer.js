// const path = require("path");
// const fs = require("fs");
// const saveToServer = async (files) => {
//   try {
//     //if upload folder does not exist, create it
//     if (!fs.existsSync(path.join(__dirname, "../../uploads"))) {
//       fs.mkdirSync(path.join(__dirname, "../../uploads"));
//     }

//     if (files === null || files === undefined) {
//       throw new Error("No file uploaded");
//     }

//     return Promise.all(
//       files.map(async (file) => {
//         const filePath = `/uploads/${Date.now()}-${file.name}`;

//         await file.mv(path.join(__dirname, `../..${filePath}`), (err) => {
//           if (err) {
//             throw new Error("Error saving file");
//           }
//         });

//         return filePath;
//       })
//     ).then((filePaths) => {
//       return filePaths;
//     });
//   } catch (error) {
//     return error;
//   }
// };

// module.exports = saveToServer;

const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  // ListObjectsCommand,
} = require("@aws-sdk/client-s3");

require('dotenv').config({
  path: "../src/config/config.env"
});

const s3 = new S3Client({
  region: "ap-northeast-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS,
    secretAccessKey: process.env.AWS_SECRET,  
  },
});

const uploadFilesOnAWS = async (files) => {
  let filePaths = [];
  console.log("files rec: ", files);

  try {
    for (let index = 0; index < files.length; index++) {
      const file = files[index];
      console.log("file: ", file);

      let { data, mimetype, size } = file;
      let originalname = Date.now() + "-" + size;
      const key = originalname;

      console.log("key: ", key, "mimetype: ", mimetype, "size: ", size, data);
      const uploadCommand = new PutObjectCommand({
        Bucket: "nisafi-data",
        Key: key,
        Body: data,
        ContentType: mimetype,
        // ACL: "public-read",
      });

      await s3.send(uploadCommand);

      filePaths.push(`https://nisafi-data.s3.amazonaws.com/${key}`);

      if ((index + 1) === files.length) {
        return filePaths
      }
    }
  } catch (err) {
    console.log("Error uploading file:", err);
    // return res.status(400).json({ errors: [{ msg: "AWS Server Error" }] });
  }
}


const deleteImageFromAWS = async (url) => {
  console.log("url: ", url);
  const deleteParams = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: url,
  };
  const result = await s3.send(new DeleteObjectCommand(deleteParams));
  console.log("Image deleted successfully", result);
}

module.exports = {
  uploadFilesOnAWS,
  deleteImageFromAWS
};