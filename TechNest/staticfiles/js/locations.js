document.addEventListener("DOMContentLoaded", () => {
    const provinceField = document.getElementById("id_province");
    const districtField = document.getElementById("id_district");
    const wardField = document.getElementById("id_ward");

    districtField.disabled = true;
    wardField.disabled = true;

    // Hàm fetch và update select field
    function fetchOptions(url, targetField, selectedValue = null) {
        fetch(url)
            .then((response) => response.json())
            .then((data) => {
                targetField.innerHTML = "";
                const unSelected = document.createElement("option");
                unSelected.value = "";
                unSelected.textContent = "Select value";
                unSelected.disabled = true;
                unSelected.selected = true;
                targetField.appendChild(unSelected);

                data.forEach((item) => {
                    const option = document.createElement("option");
                    option.value = item.code;  
                    option.textContent = item.full_name;

                    if (selectedValue && selectedValue == item.code) {
                        option.selected = true;
                    }

                    targetField.appendChild(option);
                });

                targetField.disabled = false;
            });
    }

    // Load initial selections nếu có
    const initialProvince = provinceField.value;
    const initialDistrict = districtField.value;
    const initialWard = wardField.value;

    if (initialProvince) {
        fetchOptions(
            `/locations/${initialProvince}/district/`,
            districtField,
            initialDistrict
        );
    }

    if (initialDistrict) {
        fetchOptions(
            `/locations/district/${initialDistrict}/ward/`,
            wardField,
            initialWard
        );
    }

    // Khi chọn province
    provinceField.addEventListener("change", () => {
        const provinceId = provinceField.value;

        if (provinceId) {
            fetchOptions(`/locations/${provinceId}/district/`, districtField);

            // Reset ward khi đổi province
            wardField.innerHTML = "";
            const unSelected = document.createElement("option");
            unSelected.value = "";
            unSelected.textContent = "Select value";
            unSelected.disabled = true;
            unSelected.selected = true;
            wardField.appendChild(unSelected);
            wardField.disabled = true;
        } else {
            districtField.innerHTML = "";
            districtField.disabled = true;
            wardField.innerHTML = "";
            wardField.disabled = true;
        }
    });

    // Khi chọn district
    districtField.addEventListener("change", () => {
        const districtId = districtField.value;

        if (districtId) {
            fetchOptions(`/locations/district/${districtId}/ward/`, wardField);
        } else {
            wardField.innerHTML = "";
            wardField.disabled = true;
        }
    });
});
