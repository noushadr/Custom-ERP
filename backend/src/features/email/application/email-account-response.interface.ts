/** Never includes the password — this is what's returned to the frontend
 * after setup, and whenever an account's status is checked. */
export interface EmailAccountResponse {
  id: string;
  employeeId: string;
  emailAddress: string;
  smtpHost: string;
  smtpPort: number;
  imapHost: string;
  imapPort: number;
  smtpSecure: boolean;
}
