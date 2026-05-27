/* eslint-disable react-refresh/only-export-components */

import React, { createContext, useState, useContext, useMemo } from 'react';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(() => {
    return localStorage.getItem('user') || null;
  });
  const [isGod, setIsGod] = useState(() => {
    return localStorage.getItem("god") === 'true';
  })
  const [token, setToken] = useState(() => {
    return localStorage.getItem('token') || null;
  });

  const login = (user, newToken, god = false) => {
    localStorage.setItem('user', user);
    localStorage.setItem("god", god);
    localStorage.setItem('token', newToken);
    setCurrentUser(user);
    setIsGod(god);
    setToken(newToken);
  };

  const logout = () => {
    localStorage.removeItem('user');
    localStorage.removeItem("god");
    localStorage.removeItem('token');
    setCurrentUser(null);
    setIsGod(null);
    setToken(null);
  };

  const authHeaders = useMemo( () => ({
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json",
    'X-Requested-With': "XMLHttpRequest",
    "Accept": "application/json",
  }), [token]);

  return (
    <AuthContext.Provider value={{ currentUser, token, login, logout, authHeaders, isGod }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
