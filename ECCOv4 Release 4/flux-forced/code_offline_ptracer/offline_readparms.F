C $Header: /u/gcmpack/MITgcm/pkg/offline/offline_readparms.F,v 1.12 2015/07/16 21:21:18 jmc Exp $
C $Name:  $

#include "OFFLINE_OPTIONS.h"

      SUBROUTINE OFFLINE_READPARMS( myThid )
C     *==========================================================*
C     | SUBROUTINE OFFLINE_READPARMS
C     | o Routine to initialize OFFLINE variables and constants.
C     *==========================================================*
C     | Initialize OFFLINE    parameters, read in data.off
C     *==========================================================*
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "OFFLINE.h"
#include "OFFLINE_SWITCH.h"

C     === Routine arguments ===
      INTEGER myThid

C     === Local variables ===
C     msgBuf     :: Informational/error message buffer
C     iUnit      :: Work variable for IO unit number
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit
C     Retired main data.offline file parameters
      CHARACTER*(MAX_LEN_FNAM) KPP_ghatFile
      INTEGER offlineOffsetIter

C--   Bulk Formula parameter
      NAMELIST /OFFLINE_PARM01/
     &         UvelFile, VvelFile, WvelFile, ThetFile, SaltFile,
     &         GMwxFile, GMwyFile, GMwzFile,
     &         ConvFile, KPP_DiffSFile, KPP_ghatKFile,
#ifndef ALLOW_OFFLINE_DIST_FLUXFILES
     &         HFluxFile, SFluxFile, IceFile,
#else
     &         HFlxFile, SFlxFile, IceFile,
#endif
     &         KPP_ghatFile, GGL90diffKrFile, 
     &         GM_PsiXFile, GM_PsiYFile, 
     &         GMuxFile, GMvyFile, GMuzFile, GMvzFile

      NAMELIST /OFFLINE_PARM02/
     &         offlineIter0, deltaToffline, offlineTimeOffset,
     &         offlineForcingPeriod, offlineForcingCycle,
     &         offlineLoadPrec, offlineOffsetIter

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( .NOT.useOffLine ) THEN
C-    pkg OFFLINE is not used
        _BEGIN_MASTER(myThid)
C-    Track pkg activation status:
C     print a (weak) warning if data.off is found
         CALL PACKAGES_UNUSED_MSG( 'useOffLine', ' ', 'off' )
        _END_MASTER(myThid)
        RETURN
      ENDIF

      _BEGIN_MASTER(myThid)

      WRITE(msgBuf,'(A)') ' OFFLINE_READPARMS: opening data.off'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE(
     I                          'data.off', 'OFFLINE_READPARMS',
     O                          iUnit,
     I                          myThid )

C--   Default values for params in OFFLINE_PARM01 :
      UvelFile = ' '
      VvelFile = ' '
      WvelFile = ' '
      ThetFile = ' '
      SaltFile = '  '
      GMwxFile = ' '
      GMwyFile = ' '
      GMwzFile = ' '
      GM_PsiXFile = ' '
      GM_PsiYFile = ' '
      GMuxFile = ' '
      GMvyFile = ' '
      GMuzFile = ' '
      GMvzFile = ' '
      ConvFile = ' '
      KPP_DiffSFile= ' '
      KPP_ghatKFile= ' '
      KPP_ghatFile = 'KPP_ghatFile has been replaced by KPP_ghatKFile'
#ifndef ALLOW_OFFLINE_DIST_FLUXFILES
      HFluxFile= ' '
      SFluxFile= ' '
#else
      HFlxFile= ' '
      SFlxFile= ' '
#endif
      IceFile  = ' '
      GGL90diffKrFile = ' '

C--   Read parameters from open data file
      READ(UNIT=iUnit,NML=OFFLINE_PARM01)

C--   Default values for params in OFFLINE_PARM02 :
      deltaToffline= deltaTclock
      offlineIter0 = nIter0      !initial offline field timestep
      offlineTimeOffset = 0.     !time offset
      offlineOffsetIter = UNSET_I
      offlineForcingPeriod = 2592000.
      offlineForcingCycle = 31104000.
      offlineLoadPrec = readBinaryPrec

C--   Read parameters from open data file
      READ(UNIT=iUnit,NML=OFFLINE_PARM02)

      WRITE(msgBuf,'(A)')
     &      ' OFFLINE_READPARMS: finished reading data.off'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C--   Close the open data file
      CLOSE(iUnit)

C--   Check for retired parameters still being used
      IF ( KPP_ghatFile .NE.
     &    'KPP_ghatFile has been replaced by KPP_ghatKFile' ) THEN
c       nRetired = nRetired+1
        WRITE(msgBuf,'(A,A)') 'S/R OFFLINE_READPARMS: "KPP_ghatFile"',
     &                     ' is no longer allowed in file "data.off"'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(A,A)') 'S/R OFFLINE_READPARMS: read instead ',
     &           'the product ghat*diffKz from file "KPP_ghatKFile"'
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R OFFLINE_READPARMS'
      ENDIF
      IF ( offlineOffsetIter .NE. UNSET_I ) THEN
        WRITE(msgBuf,'(A,A)') 'S/R OFFLINE_READPARMS: ',
     &   'offlineOffsetIter is no longer allowed in file "data.off"'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(A,A)') 'S/R OFFLINE_READPARMS: ',
     &   'instead set "offlineTimeOffset" to OffsetIter*deltaToffline'
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R OFFLINE_READPARMS'
      ENDIF

C--   derive other parameters:
      offlineLoadGMRedi = ( GMwxFile .NE. ' ' )
     &                .OR.( GMwyFile .NE. ' ' )
     &                .OR.( GMwzFile .NE. ' ' )
#ifndef ALLOW_OFFLINE_LOAD_GM_PSI
      offlineLoadGM_Psi = .FALSE.
#else
      offlineLoadGM_Psi = ( GM_PsiXFile .NE. ' ' )
     &                .OR.( GM_PsiYFile .NE. ' ' )
#endif
      offlineLoadKPP    = ( KPP_DiffSFile .NE. ' ' )
     &                .OR.( KPP_ghatKFile .NE. ' ' )
      offlineLoadConvec = ( ConvFile .NE. ' ' )
#ifndef ALLOW_OFFLINE_LOAD_GGL90
      offlineLoadGGL90diffkr = .FALSE.
#else
      offlineLoadGGL90diffkr = ( GGL90diffKrFile .NE. ' ' )
#endif


      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

      RETURN
      END
