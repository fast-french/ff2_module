/*********************************************************************/
/** Nom :              sqlaf_main
/** Date de cr�ation : 12/07/2010
/** Version :          1.0.0
/** Createur :         Loup Peluso
/***************************** ChangeLog *****************************/
/** V1.0.0 :
/**      Mise en place des fonctions de base n cessaires au bon
/**   fonctionnement des acc�s   la base de donn�e MySQL. Ce script
/**   contient le strict minimum pour une connection   la BDD.
/*********************************************************************/

/***************************** INCLUDES ******************************/

        // #include "usuaf_constants"
    // #include "usuaf_strtokman"
#include "usuaf_locmanip"
#include "sqlaf_constants"

/***************************** PROTOTYPES ****************************/

// DEF IN "sqlaf_main"
// Fonction d'initialisation de MySQL.
void sqlInit();

// DEF IN "sqlaf_main"
// Renvoie l'objet correspondant au Waypoint SQL.
//   o object - Waypoint SQL.
object sqlGetWaypoint();

// DEF IN "sqlaf_main"
// Fonction qui ex cute une requ te SQL.
//   > string sQuery - Requ�te � ex�cuter.
void sqlExecDirect(string sQuery);

// DEF IN "sqlaf_main"
// Fonction qui place le curseur sur la ligne suivante (en commen�ant par la premi�re).
//   o int - SQL_SUCCESS si le curseur � �t� d�plac�, SQL_ERROR sinon (fin des lignes).
int sqlFetch();

// DEF IN "sqlaf_main"
// Fonction qui permet de r�cup�rer les donn�es pr�alablement fetch�es.
//   > int iCol - Num�ro de la colonne de la ligne actuelle qui contient la valeur � r�cup�rer.
//   o string - Donn�e r�cup�re.
string sqlGetData(int iCol);

// DEF IN "sqlaf_main"
// Fonction qui permet d'ex�cuter et de r�cup�rer directement la valeur de la requ te sous
// la forme d'un entier unique (� utiliser pour r�cup�rer l'Identifiant d'un personnage par exemple).
// EAFD signifie ExecAndFetchDirect.
//   > string sQuery - Requ te   ex cuter.
//   o int - Entier r�cup�r�, r�sultat de la requ te.
int sqlEAFDSingleInt(string sQuery);

// DEF IN "sqlaf_main"
// Fonction qui permet d'ex cuter et de r�cup�rer directement la valeur de la requ te
// sous la forme d'une location (  utiliser pour r�cup�rer le point de d part d'un personnage par exemple).
// EAFD signifie ExecAndFetchDirect.
//   > string sQuery - Requ te   ex cuter.
//   o location - Location r�cup�re, r�sultat de la requ te (renvoie le point de d part du module en cas d'erreur).
location sqlEAFDSingleLocation(string sQuery);

// DEF IN "sqlaf_main"
// Fonction qui permet de r�cup�rer un entier ou, si c'est impossible, d'ex cuter une insertion.
// EAFD signifie ExecAndFetchDirect.
//   > string sSelectQuery - Requ te de s lection   ex cuter.
//   > string sInsertQuery - Insertion dans le cas d'une s lection vide.
//   > int iDepth - Profondeur de r cursivit  (  ne pas d finir).
//   o int - Entier r�cup�r�, r�sultat de la requ te.
int sqlEAFDSingleIntOrInsert(string sSelectQuery, string sInsertQuery, int iDepth = 0);

// DEF IN "sqlaf_main"
// Cette fonction cr�e une structure sub_query.
//   > string sQuery - Select correspondant   la sous-requ te d sir e.
//   > string sAlias - Alias de la sous-requ te.
//   o struct sub_query - Structure de sous-requ te.
struct sub_query sqlSetSubQuery(string sQuery, string sAlias);

// DEF IN "sqlaf_main"
// Cette fonction rajoute les caract�res de quotation en d�but et en fin de cha�ne.
//   > string sString - Cha�ne   quoter.
//   o string - Cha�ne modifi e.
string sqlQuote(string sString);

/***************************** STRUCTURES ****************************/

// Structure permettant de g rer les sous-requ�tes SQL.
struct sub_query {
    string sQuery;
    string sAlias;
};

/************************** IMPLEMENTATIONS **************************/

void sqlInit() {
    int i;
    string sStringBuffer;

    // R servation de 128 bits de m moire.
    for (i = 0; i < 8; i++) {
        sStringBuffer += "................................................................................................................................";
    }
    // Laisse de l'espace entre chaque r�sultat de requ�tes.
    SetLocalString(sqlGetWaypoint(), "NWNX!ODBC!SPACER", sStringBuffer);
}

object sqlGetWaypoint() {
    object oSQLWP = GetWaypointByTag(SQL_WP_BUFFER_TAG);
    if (oSQLWP == OBJECT_INVALID) {
        oSQLWP = CreateObject(OBJECT_TYPE_WAYPOINT, SQL_WP_BUFFER_RESREF, GetStartingLocation(), FALSE, SQL_WP_BUFFER_TAG);
    }
    return oSQLWP;
}

void sqlExecDirect(string sQuery) {
    // Envoie la requ te au module NWNX pour l' x cuter.
    SetLocalString(sqlGetWaypoint(), "NWNX!ODBC!EXEC", sQuery);
}

int sqlFetch()
{
    string sRow;
    object oWP = sqlGetWaypoint();

    SetLocalString(oWP, "NWNX!ODBC!FETCH", GetLocalString(oWP, "NWNX!ODBC!SPACER"));
    sRow = GetLocalString(oWP, "NWNX!ODBC!FETCH");
    if (GetStringLength(sRow) > 0)
    {
        SetLocalString(oWP, "NWNX_ODBC_CurrentRow", sRow);
        return SQL_SUCCESS;
    }
    else
    {
        SetLocalString(oWP, "NWNX_ODBC_CurrentRow", "");
        return SQL_ERROR;
    }
}

string sqlGetData(int iCol)
{
    int iPos;
    string sResultSet = GetLocalString(sqlGetWaypoint(), "NWNX_ODBC_CurrentRow");

    // find column in current row
    int iCount = 0;
    string sColValue = "";

    iPos = FindSubString(sResultSet, "o");
    if ((iPos == -1) && (iCol == 1))
    {
        // only one column, return value immediately
        sColValue = sResultSet;
    }
    else if (iPos == -1)
    {
        // only one column but requested column > 1
        sColValue = "";
    }
    else
    {
        // loop through columns until found
        while (iCount != iCol)
        {
            iCount++;
            if (iCount == iCol)
                sColValue = GetStringLeft(sResultSet, iPos);
            else
            {
                sResultSet = GetStringRight(sResultSet, GetStringLength(sResultSet) - iPos - 1);
                iPos = FindSubString(sResultSet, "o");
            }

            // special case: last column in row
            if (iPos == -1)
                iPos = GetStringLength(sResultSet);
        }
    }

    return sColValue;
}

int sqlEAFDSingleInt(string sQuery) {
    sqlExecDirect(sQuery);
    sqlFetch();
    string sRes = sqlGetData(1);
    if (sRes == "") {
        return SQL_ERROR;
    } else {
        return StringToInt(sRes);
    }
}

location sqlEAFDSingleLocation(string sQuery) {
    sqlExecDirect(sQuery);
    sqlFetch();
    string sRes = sqlGetData(1);
    if (sRes == "") {
        return GetStartingLocation();
    } else {
        return usuStringToLocation(sRes);
    }
}

int sqlEAFDSingleIntOrInsert(string sSelectQuery, string sInsertQuery, int iDepth = 0) {
    if (iDepth < 2) {
        // On ex cute la requ te de R�cup�ration de la valeur.
        sqlExecDirect(sSelectQuery);

        sqlFetch();

        if (TRUE) {
            // On extrait la valeur apr�s avoir r�cup�r� les donn�es.
            string sRes = sqlGetData(1);
            if (sRes == "") {
                // Aucune valeur r�cup�re, on ex cute l'insertion et on augmente d'un la profondeur de r cursivit .
                sqlExecDirect(sInsertQuery);
                return sqlEAFDSingleIntOrInsert(sSelectQuery, sInsertQuery, ++iDepth);
            } else {
                // La valeur existe, on la renvoie.
                return StringToInt(sRes);
            }
        }
    }
    // Impossible d'ex cuter les requ�tes : base de donn�e d connect e ?
    return SQL_ERROR;
}

struct sub_query sqlSetSubQuery(string sQuery, string sAlias) {
    struct sub_query sqRes;
    sqRes.sQuery = sQuery;
    sqRes.sAlias = sAlias;
    return sqRes;
}

string sqlQuote(string sString) {
    return SQL_QUOTE+sString+SQL_QUOTE;
}
