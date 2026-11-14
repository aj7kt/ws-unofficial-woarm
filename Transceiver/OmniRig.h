// -*- Mode: C++ -*-
//
// Qt ActiveQt wrapper for the OmniRig COM server (Afreet / VE3NEA OmniRig).
//
// This replaces the header that the build used to generate at configure
// time with ActiveQt's dumpcpp from the OmniRig type library found in the
// registry.  That required OmniRig to be installed on the build machine,
// could not run when cross-compiling, and Qt 6 dumpcpp (6.10, 6.12; x64 and
// arm64 alike) fails part-way through this type library.
//
// Written manually from OmniRig.ridl, https://github.com/VE3NEA/OmniRig
// commit e2f5d9ba7f0d7a3563e49fa2f3de417bfc8c749f (OmniRig 1.20, MIT
// license), type library {4FE359C5-A58F-459D-BE95-CA559FB4F270} v1.0.
// Class and member names follow what dumpcpp produced, so existing callers
// are unchanged.
//
// Everything goes through QAxObject's run-time (IDispatch) meta object:
// properties via property()/setProperty(), methods via dynamicCall(), and
// the OmniRigX events (VisibleChange(), RigTypeChange(int),
// StatusChange(int), ParamsChange(int,int), CustomReply(int,QVariant,
// QVariant)) as string-based Qt signals, e.g.
//   connect (omni_rig, SIGNAL (StatusChange (int)), ...).

#ifndef WSJTX_OMNIRIG_H_
#define WSJTX_OMNIRIG_H_

#include <QAxObject>
#include <QString>
#include <QVariant>

namespace OmniRig
{
  // enum RigParamX (bit flags)
  enum RigParamX
  {
    PM_UNKNOWN   = 0x00000001,
    PM_FREQ      = 0x00000002,
    PM_FREQA     = 0x00000004,
    PM_FREQB     = 0x00000008,
    PM_PITCH     = 0x00000010,
    PM_RITOFFSET = 0x00000020,
    PM_RIT0      = 0x00000040,
    PM_VFOAA     = 0x00000080,
    PM_VFOAB     = 0x00000100,
    PM_VFOBA     = 0x00000200,
    PM_VFOBB     = 0x00000400,
    PM_VFOA      = 0x00000800,
    PM_VFOB      = 0x00001000,
    PM_VFOEQUAL  = 0x00002000,
    PM_VFOSWAP   = 0x00004000,
    PM_SPLITON   = 0x00008000,
    PM_SPLITOFF  = 0x00010000,
    PM_RITON     = 0x00020000,
    PM_RITOFF    = 0x00040000,
    PM_XITON     = 0x00080000,
    PM_XITOFF    = 0x00100000,
    PM_RX        = 0x00200000,
    PM_TX        = 0x00400000,
    PM_CW_U      = 0x00800000,
    PM_CW_L      = 0x01000000,
    PM_SSB_U     = 0x02000000,
    PM_SSB_L     = 0x04000000,
    PM_DIG_U     = 0x08000000,
    PM_DIG_L     = 0x10000000,
    PM_AM        = 0x20000000,
    PM_FM        = 0x40000000
  };

  // enum RigStatusX
  enum RigStatusX
  {
    ST_NOTCONFIGURED = 0,
    ST_DISABLED      = 1,
    ST_PORTBUSY      = 2,
    ST_NOTRESPONDING = 3,
    ST_ONLINE        = 4
  };


  // coclass PortBits {B786DE29-3B3D-4C66-B7C4-547F9A77A21D}
  // [default] interface IPortBits {3DEE2CC8-1EA3-46E7-B8B4-3E7321F2446A}
  class PortBits
    : public QAxObject
  {
  public:
    // wrap the sub-object returned by RigX::PortBits()
    explicit PortBits (QAxObject * sub, QObject * parent = nullptr)
      : QAxObject {parent}
    {
      // adopt the COM interface of the temporary wrapper returned by
      // QAxBase::querySubObject() (initializeFrom() is protected)
      if (sub)
        {
          initializeFrom (sub);
          delete sub;
        }
    }

    bool Lock () {return dynamicCall ("Lock()").toBool ();}
    void Unlock () {dynamicCall ("Unlock()");}
    bool Rts () const {return property ("Rts").toBool ();}
    void SetRts (bool value) {setProperty ("Rts", value);}
    bool Dtr () const {return property ("Dtr").toBool ();}
    void SetDtr (bool value) {setProperty ("Dtr", value);}
    bool Cts () const {return property ("Cts").toBool ();}
    bool Dsr () const {return property ("Dsr").toBool ();}
  };

  // coclass RigX {78AECFA2-3F52-4E39-98D3-1646C00A6234}
  // [default] interface IRigX {D30A7E51-5862-45B7-BFFA-6415917DA0CF}
  class RigX
    : public QAxObject
  {
  public:
    // wrap the sub-object returned by OmniRigX::Rig1() / Rig2()
    explicit RigX (QAxObject * sub, QObject * parent = nullptr)
      : QAxObject {parent}
    {
      // adopt the COM interface of the temporary wrapper returned by
      // QAxBase::querySubObject() (initializeFrom() is protected)
      if (sub)
        {
          initializeFrom (sub);
          delete sub;
        }
    }

    QString RigType () const {return property ("RigType").toString ();}
    int ReadableParams () const {return property ("ReadableParams").toInt ();}
    int WriteableParams () const {return property ("WriteableParams").toInt ();}
    bool IsParamReadable (RigParamX param) {return dynamicCall ("IsParamReadable(int)", int (param)).toBool ();}
    bool IsParamWriteable (RigParamX param) {return dynamicCall ("IsParamWriteable(int)", int (param)).toBool ();}
    RigStatusX Status () const {return static_cast<RigStatusX> (property ("Status").toInt ());}
    QString StatusStr () const {return property ("StatusStr").toString ();}

    int Freq () const {return property ("Freq").toInt ();}
    void SetFreq (int value) {setProperty ("Freq", value);}
    int FreqA () const {return property ("FreqA").toInt ();}
    void SetFreqA (int value) {setProperty ("FreqA", value);}
    int FreqB () const {return property ("FreqB").toInt ();}
    void SetFreqB (int value) {setProperty ("FreqB", value);}
    int RitOffset () const {return property ("RitOffset").toInt ();}
    void SetRitOffset (int value) {setProperty ("RitOffset", value);}
    int Pitch () const {return property ("Pitch").toInt ();}
    void SetPitch (int value) {setProperty ("Pitch", value);}

    RigParamX Vfo () const {return static_cast<RigParamX> (property ("Vfo").toInt ());}
    void SetVfo (RigParamX value) {setProperty ("Vfo", int (value));}
    RigParamX Split () const {return static_cast<RigParamX> (property ("Split").toInt ());}
    void SetSplit (RigParamX value) {setProperty ("Split", int (value));}
    RigParamX Rit () const {return static_cast<RigParamX> (property ("Rit").toInt ());}
    void SetRit (RigParamX value) {setProperty ("Rit", int (value));}
    RigParamX Xit () const {return static_cast<RigParamX> (property ("Xit").toInt ());}
    void SetXit (RigParamX value) {setProperty ("Xit", int (value));}
    RigParamX Tx () const {return static_cast<RigParamX> (property ("Tx").toInt ());}
    void SetTx (RigParamX value) {setProperty ("Tx", int (value));}
    RigParamX Mode () const {return static_cast<RigParamX> (property ("Mode").toInt ());}
    void SetMode (RigParamX value) {setProperty ("Mode", int (value));}

    void ClearRit () {dynamicCall ("ClearRit()");}
    void SetSimplexMode (int freq) {dynamicCall ("SetSimplexMode(int)", freq);}
    void SetSplitMode (int rx_freq, int tx_freq) {dynamicCall ("SetSplitMode(int,int)", rx_freq, tx_freq);}
    int FrequencyOfTone (int tone) {return dynamicCall ("FrequencyOfTone(int)", tone).toInt ();}
    void SendCustomCommand (QVariant const& command, int reply_length, QVariant const& reply_end)
    {
      dynamicCall ("SendCustomCommand(QVariant,int,QVariant)", command, reply_length, reply_end);
    }
    int GetRxFrequency () {return dynamicCall ("GetRxFrequency()").toInt ();}
    int GetTxFrequency () {return dynamicCall ("GetTxFrequency()").toInt ();}

    // caller owns the result; wrap it with PortBits {...}
    QAxObject * PortBits () {return querySubObject ("PortBits");}
  };

  // coclass OmniRigX {0839E8C6-ED30-4950-8087-966F970F0CAE}
  // [default] interface IOmniRigX {501A2858-3331-467A-837A-989FDEDACC7D}
  // [default, source] dispinterface IOmniRigXEvents
  //   {2219175F-E561-47E7-AD17-73C4D8891AA1}
  class OmniRigX
    : public QAxObject
  {
  public:
    // Creates (or attaches to the running) OmniRig server. isNull() is
    // true if OmniRig is not installed / registered.
    explicit OmniRigX (QObject * parent = nullptr)
      : QAxObject {QStringLiteral ("{0839E8C6-ED30-4950-8087-966F970F0CAE}"), parent}
    {
    }

    int InterfaceVersion () const {return property ("InterfaceVersion").toInt ();}
    int SoftwareVersion () const {return property ("SoftwareVersion").toInt ();}
    bool DialogVisible () const {return property ("DialogVisible").toBool ();}
    void SetDialogVisible (bool value) {setProperty ("DialogVisible", value);}

    // caller owns the results; wrap them with RigX {...}
    QAxObject * Rig1 () {return querySubObject ("Rig1");}
    QAxObject * Rig2 () {return querySubObject ("Rig2");}
  };
}

#endif
