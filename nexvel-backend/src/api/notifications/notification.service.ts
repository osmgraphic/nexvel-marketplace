import { pool } from "../../database/db";

export async function createNotification(
  user: string,
  type: string,
  title: string,
  data: any,
  txHash?: string
) {
  await pool.query(
    `
    INSERT INTO notifications
    (user_address, type, title, data, tx_hash)
    VALUES ($1,$2,$3,$4,$5)
    `,
    [user.toLowerCase(), type, title, data, txHash || null]
  );
}

export async function getUserNotifications(address: string, limit: number, offset: number) {
  const result = await pool.query(
    `
    SELECT *
    FROM notifications
    WHERE user_address=$1
    ORDER BY created_at DESC
    LIMIT $2 OFFSET $3
    `,
    [address.toLowerCase(), limit, offset]
  );

  return result.rows;
}

export async function getUnreadCount(address: string) {
  const result = await pool.query(
    `
    SELECT COUNT(*) 
    FROM notifications
    WHERE user_address=$1 AND is_read=false
    `,
    [address.toLowerCase()]
  );

  return Number(result.rows[0].count);
}

export async function markAllRead(address: string) {
  await pool.query(
    `
    UPDATE notifications
    SET is_read=true
    WHERE user_address=$1
    `,
    [address.toLowerCase()]
  );
}