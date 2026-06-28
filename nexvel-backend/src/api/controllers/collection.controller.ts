import { addressSchema } from "../utils/validation";
import { getCollectionFull } from "../../services/collectionService";
import { getOrSetCache } from "../../utils/cache";

// 🔥 GET /collection/:contract/full
export async function fetchCollectionFull(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.contract);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid contract" });
    }

    const contract = parsed.data.toLowerCase();

    const data = await getOrSetCache(
      `collection:full:${contract}`,
      60,
      () => getCollectionFull(contract)
    );

    res.json(data);

  } catch (err) {
    console.error("❌ fetchCollectionFull:", err);
    res.status(500).json({ error: "Failed to fetch collection" });
  }
}