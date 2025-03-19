#include "common/common.h"
#include "common/json.h"
#include "common/mach-o.h"
#include "openssl.h"

static void _DERLength(string &strBlob, uint64_t uLength) {
    if (uLength < 128) {
        strBlob.append(1, (char)uLength);
    } else {
        uint32_t sLength = (64 - __builtin_clzll(uLength) + 7) / 8;
        strBlob.append(1, (char)(0x80 | sLength));
        sLength *= 8;
        do {
            strBlob.append(1, (char)(uLength >> (sLength -= 8)));
        } while (sLength != 0);
    }
}

static string _DER(const JValue &data) {
    string strOutput;
    if (data.isBool()) {
        strOutput.append(1, 0x01);
        strOutput.append(1, 1);
        strOutput.append(1, data.asBool() ? 1 : 0);
    } else if (data.isInt()) {
        uint64_t uVal = data.asInt64();
        strOutput.append(1, 0x02);
        _DERLength(strOutput, uVal);

        uint32_t sLength = (64 - __builtin_clzll(uVal) + 7) / 8;
        sLength *= 8;
        do {
            strOutput.append(1, (char)(uVal >> (sLength -= 8)));
        } while (sLength != 0);
    } else if (data.isString()) {
        string strVal = data.asCString();
        strOutput.append(1, 0x0c);
        _DERLength(strOutput, strVal.size());
        strOutput += strVal;
    } else if (data.isArray()) {
        string strArray;
        size_t size = data.size();
        for (size_t i = 0; i < size; i++) {
            strArray += _DER(data[i]);
        }
        strOutput.append(1, 0x30);
        _DERLength(strOutput, strArray.size());
        strOutput += strArray;
    } else if (data.isObject()) {
        string strDict;
        vector<string> arrKeys;
        data.keys(arrKeys);
        for (size_t i = 0; i < arrKeys.size(); i++) {
            string &strKey = arrKeys[i];
            string strVal = _DER(data[strKey]);

            strDict.append(1, 0x30);
            _DERLength(strDict, (2 + strKey.size() + strVal.size()));

            strDict.append(1, 0x0c);
            _DERLength(strDict, strKey.size());
            strDict += strKey;

            strDict += strVal;
        }

        strOutput.append(1, 0x31);
        _DERLength(strOutput, strDict.size());
        strOutput += strDict;
    } else {
        assert(false && "Unsupported Entitlements DER Type");
    }

    return strOutput;
}

uint32_t SlotParseGeneralHeader(const char *szSlotName, uint8_t *pSlotBase, CS_BlobIndex *pbi) {
    uint32_t uSlotLength = LE(*(((uint32_t *)pSlotBase) + 1));
    ZLog::PrintV("\n  > %s: \n", szSlotName);
    ZLog::PrintV("\ttype: \t\t0x%x\n", LE(pbi->type));
    ZLog::PrintV("\toffset: \t%u\n", LE(pbi->offset));
    ZLog::PrintV("\tmagic: \t\t0x%x\n", LE(*((uint32_t *)pSlotBase)));
    ZLog::PrintV("\tlength: \t%u\n", uSlotLength);
    return uSlotLength;
}

void SlotParseGeneralTailer(uint8_t *pSlotBase, uint32_t uSlotLength) {
    PrintDataSHASum("\tSHA-1:  \t", E_SHASUM_TYPE_1, pSlotBase, uSlotLength);
    PrintDataSHASum("\tSHA-256:\t", E_SHASUM_TYPE_256, pSlotBase, uSlotLength);
}

bool SlotParseRequirements(uint8_t *pSlotBase, CS_BlobIndex *pbi) {
    uint32_t uSlotLength = SlotParseGeneralHeader("CSSLOT_REQUIREMENTS", pSlotBase, pbi);
    if (uSlotLength < 8) {
        return false;
    }

    if (IsFileExists("/usr/bin/csreq")) {
        string strTempFile;
        StringFormat(strTempFile, "/tmp/Requirements_%llu.blob", GetMicroSecond());
        WriteFile(strTempFile.c_str(), (const char *)pSlotBase, uSlotLength);

        string strCommand;
        StringFormat(strCommand, "/usr/bin/csreq -r '%s' -t ", strTempFile.c_str());
        char result[1024] = {0};
        FILE *cmd = popen(strCommand.c_str(), "r");
        while (NULL != fgets(result, sizeof(result), cmd)) {
            printf("\treqtext: \t%s", result);
        }
        pclose(cmd);
        RemoveFile(strTempFile.c_str());
    }

    SlotParseGeneralTailer(pSlotBase, uSlotLength);

    if (ZLog::IsDebug()) {
        WriteFile("./.zsign_debug/Requirements.slot", (const char *)pSlotBase, uSlotLength);
    }
    return true;
}

// Continue with the rest of the functions similarly...