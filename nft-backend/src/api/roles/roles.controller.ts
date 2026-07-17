import { z } from "zod";
import { assignRole, getUserRole } from "./roles.service";

// 🔒 validation schemas
const roleSchema = z.object({
  address: z.string().length(42),
  role: z.enum(["ADMIN", "USER", "MODERATOR"]), // 🔥 whitelist roles
});

const addressSchema = z.string().length(42);

// ADMIN assigns role
export async function setRole(req: any, res: any) {
  try {
    const parsed = roleSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const address = parsed.data.address.toLowerCase();
    const role = parsed.data.role;

    await assignRole(address, role);

    res.json({ message: "Role updated" });

  } catch (err) {
    console.error("❌ setRole:", err);
    res.status(500).json({ error: "Failed to set role" });
  }
}

// Get role
export async function fetchRole(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data.toLowerCase();

    const role = await getUserRole(address);

    res.json({ role });

  } catch (err) {
    console.error("❌ fetchRole:", err);
    res.status(500).json({ error: "Failed to fetch role" });
  }
}