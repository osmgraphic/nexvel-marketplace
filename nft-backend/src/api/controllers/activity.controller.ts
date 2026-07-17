import { nftSchema } from "../utils/validation";

import {
  getActivity,
  getNFTActivity,
} from "../../services/activityService";

export async function fetchActivity(req: any, res: any) {
  try {
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getActivity(limit, offset);

    res.json(data);
  } catch (err) {
    console.error("❌ fetchActivity:", err);
    res.status(500).json({
      error: "Failed to fetch activity",
    });
  }
}


export async function fetchNFTActivity(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid params",
      });
    }

    const contract = parsed.data.contract.toLowerCase();
    const tokenId = parsed.data.tokenId.toString();

    const data = await getNFTActivity(contract, tokenId);

    res.json(data);
  } catch (err) {
    console.error("❌ fetchNFTActivity:", err);
    res.status(500).json({
      error: "Failed to fetch NFT activity",
    });
  }
}