module Test where

import System.PidFile(withPidFile)

test =
  do
    r <- withPidFile "mylock" (putStrLn "kek")
    case r of
      Just () -> putStrLn "I did the thing"
      Nothing -> putStrLn "I didn't"


testExn = withPidFile "mylocke" $ error "bloh"


testWait = withPidFile "mylockw" $ getLine
