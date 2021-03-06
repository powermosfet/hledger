{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Hledger.Web.Handler.AddR
  ( getAddR
  , postAddR
  ) where

import Hledger
import Hledger.Cli.Commands.Add (appendToJournalFileOrStdout)
import Hledger.Web.Import
import Hledger.Web.Widget.AddForm (addForm)
import Hledger.Web.Widget.Common (fromFormSuccess)

getAddR :: Handler ()
getAddR = postAddR

postAddR :: Handler ()
postAddR = do
  VD{caps, j, today} <- getViewData
  when (CapAdd `notElem` caps) (permissionDenied "Missing the 'add' capability")

  ((res, view), enctype) <- runFormPost $ addForm j today
  t <- txnTieKnot <$> fromFormSuccess (showForm view enctype) res
  -- XXX(?) move into balanceTransaction
  liftIO $ ensureJournalFileExists (journalFilePath j)
  liftIO $ appendToJournalFileOrStdout (journalFilePath j) (showTransaction t)
  setMessage "Transaction added."
  redirect JournalR
  where
    showForm view enctype =
      sendResponse =<< defaultLayout [whamlet|
        <h2>Add transaction
        <div .row style="margin-top:1em">
          <form#addform.form.col-xs-12.col-md-8 method=post enctype=#{enctype}>
            ^{view}
      |]
