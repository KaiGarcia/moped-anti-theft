import { Router } from "express";

const router = Router();

export default function getUsers(db) {
    router.get("/users", async (req, res) => {
        try {
            const users = db.collection("users");
            res.json(await users.find().toArray());
        } catch (error) {
            console.error("Error fetching users:", error);
            res.status(500).send("Error fetching users");
        }
    });

    return router;
}
