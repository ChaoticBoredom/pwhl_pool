import { useState, useEffect } from "react";

export const BREAKPOINT = 768;

export function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(
    () => window.innerWidth > BREAKPOINT,
  );

  useEffect(() => {
    const handler = () => setIsDesktop(window.innerWidth > BREAKPOINT);
    window.addEventListener("resize", handler);
    return () => window.removeEventListener("resize", handler);
  }, []);

  return isDesktop;
}

export function useIsMobile() {
  return !useIsDesktop();
}
