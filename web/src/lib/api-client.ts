import {
  getAccessToken,
  isAccessTokenExpired,
  refreshAccessToken,
  clearTokens,
} from "./token-manager";

export class ApiError extends Error {
  constructor(
    public status: number,
    public statusText: string,
    public body: unknown,
  ) {
    super(`API Error ${status}: ${statusText}`);
    this.name = "ApiError";
  }
}

async function getAuthHeaders(): Promise<Record<string, string>> {
  if (isAccessTokenExpired()) {
    const refreshed = await refreshAccessToken();
    if (!refreshed) {
      clearTokens();
      if (typeof window !== "undefined") {
        window.location.href = "/login";
      }
      throw new ApiError(401, "Session expired", null);
    }
  }

  const token = getAccessToken();
  if (!token) {
    throw new ApiError(401, "No access token", null);
  }

  return { Authorization: `Bearer ${token}` };
}

async function request<T>(
  url: string,
  options: RequestInit = {},
): Promise<T> {
  const authHeaders = await getAuthHeaders();

  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...authHeaders,
      ...options.headers,
    },
  });

  // On 401, attempt one refresh and retry
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      const retryHeaders = await getAuthHeaders();
      const retryResponse = await fetch(url, {
        ...options,
        headers: {
          "Content-Type": "application/json",
          ...retryHeaders,
          ...options.headers,
        },
      });

      if (!retryResponse.ok) {
        const body = await retryResponse.json().catch(() => null);
        throw new ApiError(retryResponse.status, retryResponse.statusText, body);
      }

      if (retryResponse.status === 204) return undefined as T;
      return retryResponse.json() as Promise<T>;
    }

    clearTokens();
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    }
    throw new ApiError(401, "Session expired", null);
  }

  if (!response.ok) {
    const body = await response.json().catch(() => null);
    throw new ApiError(response.status, response.statusText, body);
  }

  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export const apiClient = {
  get<T>(url: string): Promise<T> {
    return request<T>(url);
  },

  post<T>(url: string, data?: unknown): Promise<T> {
    return request<T>(url, {
      method: "POST",
      body: data ? JSON.stringify(data) : undefined,
    });
  },

  patch<T>(url: string, data: unknown): Promise<T> {
    return request<T>(url, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  },

  delete<T>(url: string): Promise<T> {
    return request<T>(url, { method: "DELETE" });
  },
};
