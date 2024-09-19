import { Router } from "express";

const router = Router();

export default function userManagement(db) {
    router.get("/login", async (req, res) => {
        try {
            const { username, password } = req.query;
            if (!username || !password) {
                return res
                    .status(400)
                    .send("Username and password are required");
            }

            const users = db.collection("users");
            const user = await users.findOne({ username, password });

            if (!user) {
                return res.status(401).send("Invalid credentials");
            }

            return res.status(200).json({status: true});
        } catch (error) {
            console.error("Error fetching users:", error);
            res.status(500).send("Error fetching users");
        }
    });

    router.get("/get-keys", async (req, res) => {
        try {
            const { username, password } = req.query;
            if (!username || !password) {
                return res
                    .status(400)
                    .send("Username and password are required");
            }

            const users = db.collection("users");
            const user = await users.findOne({ username, password });

            if (!user) {
                return res.status(404).send("User not found");
            }
            const keys = user.keys || [];

            return res.status(200).json(keys);
        } catch (error) {
            console.error("Error fetching users:", error);
            res.status(500).send("Error fetching users");
        }
    });

    router.post("/add-key", async (req, res) => {
        try {
            const { username, password, key } = req.body;
            if (!username || !password || !key) {
                return res
                    .status(400)
                    .send("Username, password, and key are required");
            }

            const users = db.collection("users");
            const user = await users.findOne({ username, password });

            if (!user) {
                return res.status(404).send("User not found");
            }

            const devices = db.collection("devices");
            const device = await devices.findOne({ key })
            if (device) {
                return res.status(404).send("Device already exist");
            }

            const keys = user.keys || [];

            if (!keys.includes(key)) {
                keys.push(key);
                await users.updateOne({ username }, { $set: { keys: keys } });
                await devices.insertOne({key: key, alert: false, user: username})
                res.status(200).json({
                    status: true,
                    message: "Key added successfully",
                });
            } else {
                res.status(200).json({
                    status: false,
                    message: "Key already exists",
                });
            }
        } catch (error) {
            console.error("Error processing key:", error);
            res.status(500).send("Error processing key");
        }
    });

    router.patch("/alert-device", async (req, res) => {
        try {
            const { username, password, key } = req.body;
            if (!username || !password || !key) {
                return res
                    .status(400)
                    .send("Username, password, and key are required");
            }

            const users = db.collection("users");
            const user = await users.findOne({ username, password });

            if (!user) {
                return res.status(404).send("User not found");
            }

            const devices = db.collection("devices");
            const device = await devices.findOne({ key })
            if (!device) {
                return res.status(404).send("Device does not exist");
            }
    
            if (device.user !== username) {
                return res.status(403).send("User does not have access to this device");
            }
    
            await devices.updateOne({ key }, { $set: { alert: true } });
            return res.status(200).send("Alert set to true for the device");
        } catch (error) {
            console.error("Error processing key:", error);
            res.status(500).send("Error processing key");
        }
    });

    router.patch("/slience-device", async (req, res) => {
        try {
            const { username, password, key } = req.body;
            if (!username || !password || !key) {
                return res
                    .status(400)
                    .send("Username, password, and key are required");
            }

            const users = db.collection("users");
            const user = await users.findOne({ username, password });

            if (!user) {
                return res.status(404).send("User not found");
            }

            const devices = db.collection("devices");
            const device = await devices.findOne({ key })
            if (!device) {
                return res.status(404).send("Device does not exist");
            }
    
            if (device.user !== username) {
                return res.status(403).send("User does not have access to this device");
            }
    
            await devices.updateOne({ key }, { $set: { alert: false } });
            return res.status(200).send("Alert set to false for the device");
        } catch (error) {
            console.error("Error processing key:", error);
            res.status(500).send("Error processing key");
        }
    });

    return router;
}
