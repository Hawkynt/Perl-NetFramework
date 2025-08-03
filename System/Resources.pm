package System::Resources; {
  use constant {
    BT_YES=>"Ja",
    BT_NO=>"Nein",
    BT_OK=>"OK",
    BT_CANCEL=>"Abbrechen",
    BT_IGNORE=>"Ignorieren",
    BT_RETRY=>"Wiederholen",
    BT_ABORT=>"Abbrechen",
    EX_WRONG_REF=>"Falsche Syntax: Ein %s Block ist in %s-Statements nicht zulässig.",
    TX_PARAMETER=>"Parametername: %s",
    EX_ARGUMENT_NULL=>"Der Wert darf nicht NULL sein.",
    EX_ASSEMBLY_NOT_FOUND=>,"Die Datei oder Assembly \"%s\" oder eine Abhängigkeit davon wurde nicht gefunden. Das System kann die angegebene Datei nicht finden.",
    EX_FILE_NOT_FOUND=>"Die angegebene Datei konnte nicht gefunden werden.",
    EX_DIR_NOT_FOUND=>"Der Pfad \"%s\" konnte nicht gefunden werden. ",
    EX_DIR_NOT_FOUND2=>"Pfadzugriffsfehler.",
    EX_IO=>"I/O Fehler: %s",
    EX_INDEX_OUT_OF_BOUNDS=>"Der Index %s ist ausserhalb des zulässigen Bereichs.",
    EX_INVALID_OPERATION=>"Die angeforderte Operation '%s' ist nicht erlaubt.",
    EX_NOT_SUPPORTED=>"Der Vorgang '%s' wird nicht unterstützt.",
    EX_NOT_IMPLEMENTED=>"Die Methode oder der Vorgang %sist nicht implementiert.",
    EX_NULL_REFERENCE=>"Die Referenz ist ungültig.",
    EX_ARGUMENT_OUT_OF_RANGE=>"Das Argument '%s' war ausserhalb des zulässigen Bereichs: %s",
    EX_CONTRACT=>"Vorbedingungsfehler: %s",
    TX_EXCEPTION=>"Eine Ausnahme vom Typ \"%s\" wurde ausgelöst.",
    TX_STACKFRAME=>"   %sin %s:Zeile %s\n",
    TX_METHOD=>"bei %s ",
    TX_MISSING_STACK=>"Stacktrace fehlt (benutze 'throw' nicht 'die' für Ausnhamen!)",
  };
};

1;