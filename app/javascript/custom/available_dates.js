// app/javascript/custom/available_dates.js
document.addEventListener("turbo:load", () => {
  const checkInInput = document.querySelector('[name$="[check_in]"]');
  const checkOutInput = document.querySelector('[name$="[check_out]"]');

  if (!checkInInput || !checkOutInput) return;

  const availableDates = JSON.parse(checkInInput.dataset.availableDates || "[]");

  const maxDate = new Date();
  maxDate.setMonth(maxDate.getMonth() + 2);
  maxDate.setDate(0);

  const checkOutFp = flatpickr(checkOutInput, {
    dateFormat: "Y/m/d",
    minDate: "today",
    maxDate: maxDate,
    enable: availableDates,
    allowInput: false,
  });

  const checkInFp = flatpickr(checkInInput, {
    dateFormat: "Y/m/d",
    minDate: "today",
    maxDate: maxDate,
    enable: availableDates,
    allowInput: false,
    onChange(selectedDates) {
      if (!selectedDates.length) return;

      const minCheckOut = new Date(selectedDates[0]);
      checkOutFp.set("minDate", minCheckOut);

      // Lọc availableDates để check_out chỉ hiển thị những ngày > check_in
      const filteredDates = availableDates.filter(dateStr => {
        const d = new Date(dateStr);
        return d > minCheckOut;
      });
      checkOutFp.set("enable", filteredDates);

      const currentOut = checkOutFp.selectedDates[0];
      if (!currentOut || currentOut <= selectedDates[0]) {
        checkOutFp.clear();
      }
    }
  });
});
