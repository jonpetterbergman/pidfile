{-# LANGUAGE OverloadedStrings #-}
-- |
-- Module: $HEADER$
--
-- Run an IO action protected by a pidfile. This will prevent
-- more than one instance of your program to run at a time.       
module System.PidFile(withPidFile) where

import           Control.Exception      (bracket)
import           Data.Bits              ((.|.))
import           Foreign.C              (CInt, CSize, eEXIST, getErrno,
                                         withCString, withCStringLen)
import           Foreign.C.Error        (throwErrno, throwErrnoIfMinus1_,
                                         throwErrnoPathIfMinus1_)
import           Foreign.Ptr            (castPtr)
import           System.Posix.Internals (c_close, c_open, c_unlink, c_write,
                                         o_CREAT, o_EXCL, o_WRONLY,
                                         withFilePath)
import           System.Posix.Process   (getProcessID)

-- | @'withPidFile' path act@ creates a pidfile at the specified @path@
--   containing the Process ID of the current process. Then @act@ is run,
--   the pidfile is removed and the result of @act@ returned wrapped in a
--   'Just'.
--
--   If the pidfile already exists, @act@ is not run, and 'Nothing' is returned.
--   Any other error while creating the pidfile results in an error.
--
--   If an exception is raised in @act@, the pidfile is removed before
--   the exception is propagated.
--
--   The pidfile is created with @O_CREAT@ and @O_EXCL@ flags to ensure that
--   an already existing pidfile is never accidentally overwitten.
withPidFile :: FilePath
            -> IO a
            -> IO (Maybe a)
withPidFile pidFile act =
  bracket (createPidFile pidFile)
          (removePidFile pidFile)
          (maybe (return Nothing) (fmap Just . const act))

createPidFile :: FilePath -> IO (Maybe CInt)
createPidFile pidFile =
  do
    fd <- withFilePath pidFile $ \fp -> c_open fp (o_CREAT .|. o_EXCL .|. o_WRONLY) 0o644
    if fd == -1 then getErrno >>= failure else success fd
   where failure errno | errno /= eEXIST = throwErrno "createPidFile: c_open"
                       | otherwise = return Nothing
         success fd =
           do
             pid <- getProcessID
             withCStringLen (show pid) $ \(buf,len) ->
               throwErrnoIfMinus1_ "createPidFile: c_write" $ c_write fd (castPtr buf) (fromIntegral len)
             return $ Just fd

removePidFile :: FilePath -> Maybe CInt -> IO ()
removePidFile _ Nothing = return ()
removePidFile pidFile (Just fd) =
  do
    throwErrnoIfMinus1_ "removePidFile: c_close" $ c_close fd
    withCString pidFile $ throwErrnoPathIfMinus1_ "removePidFile: c_unlink" pidFile . c_unlink
