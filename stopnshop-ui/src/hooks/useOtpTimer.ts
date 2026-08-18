import { useState, useEffect, useCallback, useRef } from 'react';

export function useOtpTimer(seconds: number) {
  const [timer, setTimer]       = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  const start = useCallback(() => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    setTimer(seconds);
    setIsRunning(true);
    intervalRef.current = setInterval(() => {
      setTimer((v) => {
        if (v <= 1) {
          clearInterval(intervalRef.current!);
          setIsRunning(false);
          return 0;
        }
        return v - 1;
      });
    }, 1000);
  }, [seconds]);

  const reset = useCallback(() => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    setTimer(0);
    setIsRunning(false);
  }, []);

  return { timer, isRunning, start, reset };
}
