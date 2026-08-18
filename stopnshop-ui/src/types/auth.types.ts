export interface LoginRequest {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface SignupRequest {
  firstName: string;
  lastName: string;
  email: string;
  mobile: string;
  countryCode?: string;
  password: string;
  gender?: string;
}

export interface UserProfile {
  id: number;
  mobile: string;
  name?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  role: string;
  countryCode?: string;
  gender?: string;
  dateOfBirth?: string;
  createdAt?: string;
  isFirstLogin?: boolean;
}

export interface AuthTokenResponse {
  token: string;
  expiresAt: string;
  user: UserProfile;
}

export interface UpdateProfileRequest {
  name?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  gender?: string;
  dateOfBirth?: string;
}
