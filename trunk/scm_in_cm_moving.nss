/*********************************************************************/
/** Nom :              scm_in_cm_moving
/** Date de cr�ation : 08/08/2010
/** Version :          1.0.0
/** Cr�ateur :         Peluso Loup
/***************************** ChangeLog *****************************/
/** V1.0.0 (par Peluso Loup) :
/**      Script contenant la liste des commandes relatives aux
/**    d�placements des personnages.
/*********************************************************************/

/***************************** INCLUDES ******************************/

    // Donnees de config.
    // #include "cos_in_config"

    // Fonctions de manipulation des cha�nes de caract�res.
    // #include "usu_in_strings"
// Fonctions de manipulation et de tra�tement.
#include "scm_in_util"

// Fonctions de d�placement.
#include "usu_in_move"

/***************************** CONSTANTES ****************************/

// Constantes de langue.
const string L_YOU_SAVED_THIS_POSITION_IN_THE_VARIABLE = "Vous avez sauvegard� cette position dans la variable";
const string L_YOU_CAN_REUSE_IT_TO_RETURN_THERE_AUTOMATICALLY = "Vous pourrez la r�utiliser pour y revenir automatiquement.";

// Nom des commandes.
const string SCM_CM_MOVE_TO = "moveto";
const string SCM_CM_SAVE_LOC = "savepos";

// Param�tres des commandes.
const string SCM_PAR_LOCAL_LOCATION_VARIABLE_NAME = "var";
const string SCM_PAR_WAYPOINT_TAG = "tag";
const string SCM_PAR_TO_LOCATION = "loc";
const string SCM_PAR_TO_WAYPOINT = "wp";
const string SCM_PAR_RUN = "run";
const string SCM_PAR_JUMP = "jump";

// Messages d'erreur.
const string ERR_IMPOSSIBLE_TO_MOVE_TO_WAYPOINT_AND_TO_RENT = "Impossible de se d�placer � la fois vers un Waypoint et vers une Location.";
const string ERR_VARIABLE_NAME_PARAMETER_NOT_PASSED_ON = "Param�tre de nom de variable non transmit.";
const string ERR_WAYPOINT_DESTINATION_INVALID = "Le Waypoint de destination est invalide.";
const string ERR_MOVING_TYPE_NOT_DEFINED = "Le type de d�placement (vers un Waypoint ou vers une Location) n'a pas �t� d�fini.";

/***************************** PROTOTYPES ****************************/

// DEF IN "scm_in_commands"
// Fonction qui d�place un personnage vers un point du module.
//   > string sCommand - Commande � tra�ter.
//   > object oPC - Source de la requ�te.
//   o string - Cha�ne vide.
string scmMoveToCommand(string sCommand, object oPC);

// DEF IN "scm_in_commands"
// Fonction qui sauvegarde la position actuelle du personnage.
//   > string sCommand - Commande � tra�ter.
//   > object oPC - Source de la requ�te.
//   o string - Cha�ne vide.
string scmSaveLocCommand(string sCommand, object oPC);

/************************** IMPLEMENTATIONS **************************/

string scmSaveLocCommand(string sCommand, object oPC) {
    // On r�cup�re le nom de la variable choisi par le joueur.
    string sVarName = scmGetParameterValue(sCommand, SCM_PAR_LOCAL_LOCATION_VARIABLE_NAME);
    // On r�cup�re la position actuelle du PJ.
    if (GetIsPC(oPC)) {
        location lLoc = GetLocation(oPC);
        // On sauvegarde la position de fa�on persistante.
        SetLocalLocation(oPC, sVarName, lLoc);
        SendMessageToPC(oPC, L_YOU_SAVED_THIS_POSITION_IN_THE_VARIABLE+" "+sVarName+".\n"+
                             L_YOU_CAN_REUSE_IT_TO_RETURN_THERE_AUTOMATICALLY);
    }
    return SCM_EMPTY_RESULT;
}

string scmMoveToCommand(string sCommand, object oPC) {
    // Est-ce que le personnage source est valide ?
    if (!GetIsPC(oPC)) {
        return SCM_EMPTY_RESULT; 
    }
    
    // Est-ce qu'on se d�place vers une location ?
    int iToLocation = scmIsParameterDefined(sCommand, SCM_PAR_TO_LOCATION);
    // Est-ce qu'on se d�place vers un waypoint ?
    int iToWaypoint = scmIsParameterDefined(sCommand, SCM_PAR_TO_WAYPOINT);
    
    // Impossible de faire les deux.
    if (iToLocation && iToWaypoint) {
        scmSendCommandErrorMessage(oPC, ERR_IMPOSSIBLE_TO_MOVE_TO_WAYPOINT_AND_TO_RENT);
        return SCM_EMPTY_RESULT;
    }
  
    // Au moins un des deux dois �tre d�fini.
    if (!(iToLocation || iToWaypoint)) {
        scmSendCommandErrorMessage(oPC, ERR_MOVING_TYPE_NOT_DEFINED);
        return SCM_EMPTY_RESULT;
    } 
    
    // Variables contenant les informations pass�es en param�tre de la commande pour d�placer le PJ.
    location lDest;
    string sWaypointTag;
    string sLocalLocationVarName;
    
    if (iToLocation) {
        // On r�cup�re la location de destination.
        sLocalLocationVarName = scmGetParameterValue(sCommand, SCM_PAR_LOCAL_LOCATION_VARIABLE_NAME);
        if (sLocalLocationVarName == SCM_EMPTY_PARAMETER) {
            scmSendCommandErrorMessage(oPC, ERR_VARIABLE_NAME_PARAMETER_NOT_PASSED_ON);
            return SCM_EMPTY_RESULT;
        }
        lDest = GetLocalLocation(oPC, sLocalLocationVarName);
    } else if (iToWaypoint) {
        sWaypointTag = scmGetParameterValue(sCommand, SCM_PAR_WAYPOINT_TAG);
        object oWP = GetWaypointByTag(sWaypointTag);
        if (!GetIsObjectValid(oWP)) {
            scmSendCommandErrorMessage(oPC, ERR_WAYPOINT_DESTINATION_INVALID);
            return SCM_EMPTY_RESULT;
        }
        lDest = GetLocation(oWP);
    }
    
    // Est-ce le PJ va se d�placer en courant ?
    int iRun = scmIsParameterDefined(sCommand, SCM_PAR_RUN);

    // Est-ce qu'on va d�placer le PJ instantan�ment ?
    int iJump = scmIsParameterDefined(sCommand, SCM_PAR_JUMP);

    // On d�place le personnage jusqu'� la location sauv�e.
    usuMoveToLocation(oPC, lDest, iRun, iJump);

    return SCM_EMPTY_RESULT;
}