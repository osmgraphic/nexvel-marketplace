import { getUserRole } from "../roles/roles.service"

export function requireRole(requiredRole: string) {
  return async (req: any, res: any, next: any) => {

    const address = req.user.address

    const userRole = await getUserRole(address)

    if (userRole !== requiredRole) {
      return res.status(403).json({
        error: `Access denied. Required role: ${requiredRole}`
      })
    }

    next()
  }
}