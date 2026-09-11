#include <depthai/device/Version.hpp>
#include <semver.hpp>
#include <string>

namespace dai {

// semver 1.0.0 removed the `semver::prerelease` enum and the (major, minor, patch, prerelease,
// preReleaseVersion) constructor it fed. A pre-release is now the SemVer spec's dot-separated
// tag string, so the type and its number are rendered into that tag rather than mapped to an
// enumerator: ALPHA with 1 becomes "alpha.1", and a type with no number becomes just "alpha".
// PreReleaseType::NONE is the empty tag, which is how semver spells "not a pre-release".
std::string convertPreReleaseToSemverTag(Version::PreReleaseType type, const std::optional<uint16_t>& preReleaseVersion) {
    std::string tag;
    switch(type) {
        case Version::PreReleaseType::ALPHA:
            tag = "alpha";
            break;
        case Version::PreReleaseType::BETA:
            tag = "beta";
            break;
        case Version::PreReleaseType::RC:
            tag = "rc";
            break;
        case Version::PreReleaseType::NONE:
            return {};
        default:
            throw std::invalid_argument("Invalid pre-release type");
    }

    if(preReleaseVersion.has_value()) {
        tag += "." + std::to_string(*preReleaseVersion);
    }
    return tag;
}

class Version::Impl {
   public:
    explicit Impl(const std::string& v) {
        auto posBuild = v.find('+');

        if(posBuild != std::string::npos) {
            buildInfo = v.substr(posBuild + 1);
        }

        auto semverStr = v.substr(0, posBuild);

        if(semverStr.empty() || !semver::valid(semverStr)) {
            throw std::invalid_argument("Invalid version string");
        }

        // semver 1.0.0 dropped the string constructor in favour of a free parse() that reports
        // failure rather than throwing. validity is already checked above, so a failure here is
        // a disagreement between valid() and parse() and not bad input.
        if(!semver::parse(semverStr, version)) {
            throw std::invalid_argument("Invalid version string");
        }
    }

    Impl(unsigned major,
         unsigned minor,
         unsigned patch,
         const PreReleaseType& type,
         const std::optional<uint16_t>& preReleaseVersion,
         const std::string& buildInfo)
        : version(major, minor, patch, convertPreReleaseToSemverTag(type, preReleaseVersion)), buildInfo(buildInfo) {}

    bool operator==(const Impl& other) const {
        return version == other.version;
    }

    bool operator<(const Impl& other) const {
        return version < other.version;
    }

    std::string toString() const {
        std::string result = version.to_string();
        if(!buildInfo.empty()) {
            result += "+" + buildInfo;
        }
        return result;
    }

    std::string toStringSemver() const {
        return version.to_string();
    }

    std::string getBuildInfo() const {
        return buildInfo;
    }

   private:
    // semver 1.0.0 made version a class template over its component integer types.
    semver::version<> version;
    std::string buildInfo;
};

// Definitions of Version member functions
Version::Version(const std::string& v) : pimpl(spimpl::make_impl<Impl>(v)) {}

Version::Version(
    unsigned major, unsigned minor, unsigned patch, const PreReleaseType& type, const std::optional<uint16_t>& preReleaseVersion, const std::string& buildInfo)
    : pimpl(spimpl::make_impl<Impl>(major, minor, patch, type, preReleaseVersion, buildInfo)) {}

bool Version::operator==(const Version& other) const {
    return *pimpl == *other.pimpl;
}

bool Version::operator<(const Version& other) const {
    return *pimpl < *other.pimpl;
}

std::string Version::toString() const {
    return pimpl->toString();
}

std::string Version::toStringSemver() const {
    return pimpl->toStringSemver();
}

std::string Version::getBuildInfo() const {
    return pimpl->getBuildInfo();
}

}  // namespace dai