import { pool } from "../../database/db"

export async function assignRole(address: string, role: string) {
  await pool.query(
    `
    INSERT INTO roles (address, role)
    VALUES ($1, $2)
    ON CONFLICT (address)
    DO UPDATE SET role = EXCLUDED.role
    `,
    [address.toLowerCase(), role]
  )
}

export async function getUserRole(address: string) {
  const result = await pool.query(
    `
    SELECT role FROM roles
    WHERE address = $1
    `,
    [address.toLowerCase()]
  )

  if (result.rows.length === 0) return "USER"

  return result.rows[0].role
}