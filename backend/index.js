import express, { json } from "express";
import { MongoClient } from "mongodb";
import cors from "cors";
import dotenv from "dotenv";
import helmet from "helmet";
import morgan from "morgan";

import userManagement from "./routes/userRoutes.js";

dotenv.config();
const app = express();
const port = process.env.PORT || 3000;
let db;

// Middleware to parse JSON bodies
app.use(json());
app.use(cors());
app.use(helmet());
app.use(morgan("combined"));

// Connect to MongoDB
async function connectToDatabase() {
    if (!db) {
        try {
            const client = new MongoClient(process.env.MONGODB_URI);
            await client.connect();
            db = client.db(process.env.DB_NAME);
            console.log("Connected to MongoDB!");
        } catch (error) {
            console.error("Error connecting to MongoDB:", error);
        }
    }
}

// Root route
app.get("/", async (req, res) => {
    res.send("Backend up and running.");
    await connectToDatabase();
});

app.use("/api", userManagement(db));
await connectToDatabase();

// Boot server
app.listen(port, async () => {
    console.log(`Server running on http://localhost:${port}`);
});
