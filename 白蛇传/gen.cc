#include <iostream>
#include <unordered_map>
#include <sstream>

int main() {
    std::unordered_map<std::string, std::string> voiceMap;
    voiceMap["旁白"] = "zh-CN-XiaoyouNeural";
    voiceMap["皇帝"] = "zh-CN-YunjianNeural";
    voiceMap["H"] = "zh-CN-YunjianNeural";

    voiceMap["许仙"] = "zh-CN-YunxiaNeural";
    voiceMap["X"] = "zh-CN-YunxiaNeural";

    voiceMap["李公甫"] = "zh-CN-YunfengNeural";
    voiceMap["L"] = "zh-CN-YunfengNeural";

    voiceMap["法海"] = "zh-CN-YunxiNeural";
    voiceMap["F"] = "zh-CN-YunxiNeural";

    voiceMap["杨知县"] = "zh-CN-YunzeNeural";
    voiceMap["Y"] = "zh-CN-YunzeNeural";

    voiceMap["观音"] = "zh-CN-YunyeNeural";
    voiceMap["G"] = "zh-CN-YunyeNeural";

    voiceMap["杨知县夫人"] = "zh-CN-XiaoyiNeural";
    voiceMap["F"] = "zh-CN-XiaoyiNeural";

    voiceMap["王庭张"] = "zh-CN-XiaoruiNeural";
    voiceMap["W"] = "zh-CN-XiaoruiNeural";

    voiceMap["白蛇"] = "zh-CN-XiaohanNeural";
    voiceMap["B"] = "zh-CN-XiaohanNeural";

    voiceMap["王员外"] = "zh-CN-YunxiNeural";
    voiceMap["W"] = "zh-CN-YunxiNeural";

    voiceMap["捕快"] = "zh-CN-YunxiNeural";
    voiceMap["W"] = "zh-CN-YunxiNeural";

    voiceMap["姣容"] = "zh-CN-YunxiNeural";
    voiceMap["J"] = "zh-CN-YunxiNeural";

    std::cout << "<!--ID=B7267351-473F-409D-9765-754A8EBCDE05;Version=1|{\"VoiceNameToIdMapItems\":[{\"Id\":\"d6814675-a0c5-4e09-9387-bd9b44d3e733\",\"Name\":\"Microsoft Server Speech Text to Speech Voice (zh-CN, XiaoyouNeural)\",\"ShortName\":\"zh-CN-XiaoyouNeural\",\"Locale\":\"zh-CN\",\"VoiceType\":\"StandardVoice\"},{\"Id\":\"39947851-46d7-4561-8199-2fd8bdc49ba6\",\"Name\":\"Microsoft Server Speech Text to Speech Voice (zh-CN, YunjianNeural)\",\"ShortName\":\"zh-CN-YunjianNeural\",\"Locale\":\"zh-CN\",\"VoiceType\":\"StandardVoice\"},{\"Id\":\"66dca810-157a-48a7-9a9c-cac3147734e8\",\"Name\":\"Microsoft Server Speech Text to Speech Voice (zh-CN, YunxiaNeural)\",\"ShortName\":\"zh-CN-YunxiaNeural\",\"Locale\":\"zh-CN\",\"VoiceType\":\"StandardVoice\"}]}-->\n<!--ID=FCB40C2B-1F9F-4C26-B1A1-CF8E67BE07D1;Version=1|{\"Files\":{}}-->\n<!--ID=5B95B1CC-2C7B-494F-B746-CF22A0E779B7;Version=1|{\"Locales\":{\"zh-CN\":{\"AutoApplyCustomLexiconFiles\":[{}]}}}-->\n<speak xmlns=\"http://www.w3.org/2001/10/synthesis\" xmlns:mstts=\"http://www.w3.org/2001/mstts\" xmlns:emo=\"http://www.w3.org/2009/10/emotionml\" version=\"1.0\" xml:lang=\"zh-CN\">\n";

    std::string line;
    while (std::getline(std::cin, line)) {
        std::size_t pos = line.find("> ");
        if (pos != std::string::npos) {
            std::string person = line.substr(1, pos-1);
            std::string dialogue = line.substr(pos+2);
            std::cout << "<voice name=\"" << voiceMap[person] << "\">" << dialogue << "</voice>\n";
        } else {
            if (line.size() < 1) {
                continue;
            }

            std::size_t pos = line.find(">");
            if (pos != std::string::npos) {
                // 那么在'>'后面添加一个空格
                line.insert(pos+1, " ");
                std::size_t pos = line.find("> ");
                std::string person = line.substr(1, pos-1);
                std::string dialogue = line.substr(pos+2);
                std::cout << "<voice name=\"" << voiceMap[person] << "\">" << dialogue << "</voice>\n";
            } else {
                std::cout << "<voice name=\"" << voiceMap["旁白"] << "\">" << line << "</voice>\n";
            }
        }
    }

    std::cout << "</speak>\n";

    return 0;
}

