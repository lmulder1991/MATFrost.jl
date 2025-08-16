#include "mex.hpp"
#include "mexAdapter.hpp"

#include <tuple>
// stdc++ lib
#include <string>
#include <complex>
#include <memory>
//
// extern "C" {
// #include "matfrost.h"
// }
//


namespace MATFrost::ConvertToMATLAB {

    matlab::data::Array read(BufferedInputStream& is);

    template<typename T>
    matlab::data::Array read_primitive(BufferedInputStream& is, matlab::data::ArrayDimensions dims) {
        size_t nel = 1;
        for (const auto dim : dims){
            nel *= dim;
        }

        matlab::data::ArrayFactory factory;
        matlab::data::buffer_ptr_t<T> buf = factory.createBuffer<T>(nel);

        is.read(reinterpret_cast<uint8_t *>(buf.get()), sizeof(T)*nel);

        return factory.createArrayFromBuffer<T>(dims, std::move(buf));

    }

    matlab::data::Array read_string(BufferedInputStream& is, matlab::data::ArrayDimensions dims) {
        size_t nel = 1;
        for (const auto dim : dims){
            nel *= dim;
        }

        matlab::data::ArrayFactory factory;

        matlab::data::StringArray strarr = factory.createArray<matlab::data::MATLABString>(dims);

        for (auto e : strarr) {
            size_t strbytes;

            is.read(reinterpret_cast<uint8_t *>(&strbytes), sizeof(size_t));

            auto strdata = std::vector<uint8_t>(strbytes);

            is.read(strdata.data(), strbytes);
            e = matlab::engine::convertUTF8StringToUTF16String(std::string(reinterpret_cast<char*>(strdata.data()), strbytes));

        }
        return strarr;
    }
    matlab::data::Array read_cell(BufferedInputStream& is, matlab::data::ArrayDimensions dims) {
        matlab::data::ArrayFactory factory;

        matlab::data::CellArray carr = factory.createCellArray(dims);

        for (auto e : carr) {
            e = read(is);
        }
        return carr;
    }

    matlab::data::Array read_struct(BufferedInputStream& is, matlab::data::ArrayDimensions dims) {
        size_t nel = 1;
        for (const auto dim : dims){
            nel *= dim;
        }
        size_t nfields;

        is.read(reinterpret_cast<uint8_t *>(&nfields), sizeof(size_t));

        std::vector<std::string> fieldnames(nfields);
        for (size_t i = 0; i < nfields; i++){
            size_t strbytes;

            is.read(reinterpret_cast<uint8_t *>(&strbytes), sizeof(size_t));

            auto strdata = std::vector<uint8_t>(strbytes);

            is.read(strdata.data(), strbytes);

            fieldnames[i] = std::string(reinterpret_cast<char*>(strdata.data()), strbytes);
        }

        matlab::data::ArrayFactory factory;


        matlab::data::StructArray matstruct = factory.createStructArray(dims, fieldnames);

        for (auto e : matstruct) {
            for (size_t fi = 0; fi < nfields; fi++){
                e[fieldnames[fi]] = read(is);
            }
        }

        return matstruct;
    }

//
// matlab::data::Array convert(const MATFrostArray mfa);
//
//
// template<typename T>
// matlab::data::Array convert_primitive(const MATFrostArray mfa) {
//     matlab::data::ArrayDimensions dims(mfa.ndims);
//
//     size_t nel = 1;
//     for (size_t i = 0; i < mfa.ndims; i++){
//         dims[i] = mfa.dims[i];
//         nel *= dims[i];
//     }
//
//     matlab::data::ArrayFactory factory;
//
//     matlab::data::buffer_ptr_t<T> buf = factory.createBuffer<T>(nel);
//
//     memcpy(buf.get(), mfa.data, sizeof(T)*nel);
//
//     return factory.createArrayFromBuffer<T>(dims, std::move(buf));
//
// }
//
// matlab::data::Array convert_string(const MATFrostArray mfa){
//     matlab::data::ArrayDimensions dims(mfa.ndims);
//
//     size_t nel = 1;
//     for (size_t i = 0; i < mfa.ndims; i++){
//         dims[i] = mfa.dims[i];
//         nel *= dims[i];
//     }
//
//     matlab::data::ArrayFactory factory;
//
//     matlab::data::StringArray strarr = factory.createArray<matlab::data::MATLABString>(dims);
//
//     size_t eli = 0;
//     const char** strdata = (const char**) mfa.data;
//     for (auto e : strarr) {
         // e = matlab::engine::convertUTF8StringToUTF16String(strdata[eli]);
         // eli++;
//     }
//     return strarr;
// }
//
//
// matlab::data::Array convert_struct(const MATFrostArray mfa) {
//     matlab::data::ArrayDimensions dims(mfa.ndims);
//
//     size_t nel = 1;
//     for (size_t i = 0; i < mfa.ndims; i++){
//         dims[i] = mfa.dims[i];
//         nel *= dims[i];
//     }
//
//     std::vector<std::string> fieldnames(mfa.nfields);
//     for (size_t i = 0; i < mfa.nfields; i++){
//         fieldnames[i] = mfa.fieldnames[i];
//     }
//
//     matlab::data::ArrayFactory factory;
//
//     matlab::data::StructArray matstruct = factory.createStructArray(dims, fieldnames);
//
//     size_t eli = 0;
//     const MATFrostArray** mfafields = (const MATFrostArray**) mfa.data;
//     for (auto e : matstruct) {
//         for (size_t fi = 0; fi < mfa.nfields; fi++){
//             e[fieldnames[fi]] = convert(mfafields[eli][0]);
//
//             eli++;
//         }
//     }
//
//     return matstruct;
// }
//
// matlab::data::Array convert_cell(const MATFrostArray mfa) {
//     matlab::data::ArrayDimensions dims(mfa.ndims);
//
//     size_t nel = 1;
//     for (size_t i = 0; i < mfa.ndims; i++){
//         dims[i] = mfa.dims[i];
//         nel *= dims[i];
//     }
//
//     matlab::data::ArrayFactory factory;
//
//     matlab::data::CellArray carr = factory.createCellArray(dims);
//
//     size_t eli = 0;
//     const MATFrostArray** mfafields = (const MATFrostArray**) mfa.data;
//     for (auto e : carr) {
//         e = convert(mfafields[eli][0]);
//         eli++;
//     }
//
//     return carr;
// }
//
//
//
matlab::data::Array read(BufferedInputStream& is){
    int32_t type;
    size_t ndims;
    is.read(reinterpret_cast<uint8_t *>(&type), sizeof(int32_t));
    is.read(reinterpret_cast<uint8_t *>(&ndims), sizeof(size_t));
    matlab::data::ArrayDimensions dims(ndims);
    is.read(reinterpret_cast<uint8_t *>(dims.data()), sizeof(size_t)*ndims);

    switch (static_cast<matlab::data::ArrayType>(type)) {
        case matlab::data::ArrayType::CELL:
             return read_cell(is, dims);
        case matlab::data::ArrayType::STRUCT:
            return read_struct(is, dims);
        case matlab::data::ArrayType::MATLAB_STRING:
             return read_string(is, dims);
        case matlab::data::ArrayType::LOGICAL:
            return read_primitive<bool>(is, dims);

        case matlab::data::ArrayType::SINGLE:
            return read_primitive<float>(is, dims);
        case matlab::data::ArrayType::DOUBLE:
            return read_primitive<double>(is, dims);

        case matlab::data::ArrayType::INT8:
            return read_primitive<int8_t>(is, dims);
        case matlab::data::ArrayType::UINT8:
            return read_primitive<uint8_t>(is, dims);
        case matlab::data::ArrayType::INT16:
            return read_primitive<int16_t>(is, dims);
        case matlab::data::ArrayType::UINT16:
            return read_primitive<uint16_t>(is, dims);
        case matlab::data::ArrayType::INT32:
            return read_primitive<int32_t>(is, dims);
        case matlab::data::ArrayType::UINT32:
            return read_primitive<uint32_t>(is, dims);
        case matlab::data::ArrayType::INT64:
            return read_primitive<int64_t>(is, dims);
        case matlab::data::ArrayType::UINT64:
            return read_primitive<uint64_t>(is, dims);

        case matlab::data::ArrayType::COMPLEX_SINGLE:
            return read_primitive<std::complex<float>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_DOUBLE:
            return read_primitive<std::complex<double>>(is, dims);

        case matlab::data::ArrayType::COMPLEX_UINT8:
            return read_primitive<std::complex<uint8_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_INT8:
            return read_primitive<std::complex<int8_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_UINT16:
            return read_primitive<std::complex<uint16_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_INT16:
            return read_primitive<std::complex<int16_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_UINT32:
            return read_primitive<std::complex<uint32_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_INT32:
            return read_primitive<std::complex<int32_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_UINT64:
            return read_primitive<std::complex<uint64_t>>(is, dims);
        case matlab::data::ArrayType::COMPLEX_INT64:
            return read_primitive<std::complex<int64_t>>(is, dims);

        default:
            throw matlab::engine::MATLABException("matfrostjulia:conversion:typeNotSupported", u"MATFrost does not support conversions to MATLAB from Julia with array_type: ");

    }
}




}

